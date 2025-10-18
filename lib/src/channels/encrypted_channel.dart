import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

import '../auth/authorizer.dart';
import 'private_channel.dart';

/// A private channel with end-to-end encryption.
///
/// Encrypted channels extend private channels with automatic decryption
/// of event payloads using AES-256-CBC encryption. They require both
/// authentication (like private channels) and an encryption master key
/// for decrypting event data.
///
/// Encrypted channels must have names starting with "private-encrypted-"
/// and follow the Pusher protocol for encrypted channels.
///
/// Example:
/// ```dart
/// final channel = client.encryptedChannel(
///   'private-encrypted-messages',
///   encryptionMasterKey: 'your-32-byte-base64-encoded-key',
/// );
///
/// await channel.subscribe();
///
/// channel.on('message').listen((event) {
///   // event.data is already decrypted
///   print('Decrypted message: ${event.data}');
/// });
/// ```
class EncryptedChannel extends PrivateChannel {
  /// The master encryption key used for decrypting events.
  ///
  /// This should be a base64-encoded 32-byte key that matches the
  /// encryption key used by the server.
  final String encryptionMasterKey;

  /// Creates a new EncryptedChannel instance.
  ///
  /// [name] The name of the encrypted channel (must start with "private-encrypted-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [socketId] The socket ID for authentication.
  /// [sendMessage] Callback for sending WebSocket messages.
  /// [encryptionMasterKey] The master key for decrypting events (base64-encoded 32-byte key).
  ///
  /// Throws [ArgumentError] if the channel name doesn't start with "private-encrypted-"
  /// or if the encryption key is invalid.
  EncryptedChannel({required super.name, required super.authorizer, required super.authEndpoint, required super.socketId, required super.sendMessage, required this.encryptionMasterKey}) {
    validateEncryptedChannelName(name);
    _validateEncryptionKey();
  }

  /// Validates the encryption key format and length.
  ///
  /// Throws [ArgumentError] if the key is empty or invalid.
  void _validateEncryptionKey() {
    if (encryptionMasterKey.isEmpty) {
      throw ArgumentError('Encryption master key cannot be empty');
    }

    // Validate that it's a valid base64 string
    try {
      final decoded = base64.decode(encryptionMasterKey);
      if (decoded.length != 32) {
        throw ArgumentError(
          'Encryption master key must be a base64-encoded 32-byte key. '
          'Decoded length: ${decoded.length} bytes',
        );
      }
    } catch (e) {
      if (e is ArgumentError) {
        rethrow;
      }
      throw ArgumentError('Encryption master key must be a valid base64-encoded string: $e');
    }
  }

  /// Handles incoming events for this channel.
  ///
  /// This method intercepts events, decrypts the payload, and passes
  /// the decrypted data to the parent class for normal event handling.
  ///
  /// [eventName] The name of the event.
  /// [data] The event data (should be encrypted according to Pusher protocol).
  @override
  void handleEvent(String eventName, dynamic data) {
    try {
      // Decrypt the event data
      final decryptedData = _decryptEventData(data);
      // Pass decrypted data to parent class
      super.handleEvent(eventName, decryptedData);
    } catch (e) {
      // Handle decryption errors gracefully
      // Log error (without exposing sensitive data) and emit error event
      _handleDecryptionError(eventName, e);
    }
  }

  /// Decrypts event data using AES-256-CBC.
  ///
  /// [data] The encrypted event data from the server.
  ///
  /// Returns the decrypted data (decoded from JSON).
  ///
  /// Throws [FormatException] if the data format is invalid.
  /// Throws [Exception] if decryption fails.
  dynamic _decryptEventData(dynamic data) {
    // Parse the encrypted data structure
    // Expected format: { "ciphertext": "...", "nonce": "..." }
    if (data is! Map<String, dynamic>) {
      throw FormatException('Encrypted event data must be a JSON object');
    }

    final ciphertext = data['ciphertext'] as String?;
    final nonce = data['nonce'] as String?;

    if (ciphertext == null || ciphertext.isEmpty) {
      throw FormatException('Encrypted event data missing "ciphertext" field');
    }

    if (nonce == null || nonce.isEmpty) {
      throw FormatException('Encrypted event data missing "nonce" field');
    }

    try {
      // Decode the encryption key
      final keyBytes = base64.decode(encryptionMasterKey);
      final key = encrypt.Key(keyBytes);

      // Decode the IV (nonce)
      final ivBytes = base64.decode(nonce);
      final iv = encrypt.IV(ivBytes);

      // Create the encrypter with AES CBC mode
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      // Decrypt the ciphertext
      final decrypted = encrypter.decrypt64(ciphertext, iv: iv);

      // Parse the decrypted JSON
      return jsonDecode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Handles decryption errors gracefully.
  ///
  /// This method emits an error event that applications can listen to.
  /// The error is not logged to avoid exposing sensitive data in production.
  ///
  /// [eventName] The name of the event that failed to decrypt.
  /// [error] The error that occurred during decryption.
  void _handleDecryptionError(String eventName, Object error) {
    // Emit an error event that applications can listen to
    // We use a special event name to distinguish decryption errors
    final errorData = {'error': 'decryption_failed', 'event': eventName, 'message': 'Failed to decrypt event data'};

    // Call parent's handleEvent with the error data
    // This allows apps to listen for decryption errors
    super.handleEvent('pusher:decryption_error', errorData);
  }
}
