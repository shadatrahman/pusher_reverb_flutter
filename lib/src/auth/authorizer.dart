import 'dart:async';

import '../models/exceptions.dart';

/// A function that provides authentication headers for private channel access.
///
/// This function is called when subscribing to a private channel to obtain
/// the necessary authentication headers for the authorization request.
///
/// [channelName] The name of the private channel being subscribed to.
/// [socketId] The socket ID assigned by the server upon connection.
///
/// Returns a Future that completes with a Map of authentication headers.
/// The headers should include any necessary tokens or credentials for
/// authenticating the private channel subscription.
typedef Authorizer = Future<Map<String, String>> Function(String channelName, String socketId);

/// Validates that a channel name is a valid private channel name.
///
/// Private channels must start with the "private-" prefix.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid private channel name.
void validatePrivateChannelName(String channelName) {
  if (channelName.isEmpty) {
    throw InvalidChannelNameException('Channel name cannot be empty', channelName);
  }

  if (!channelName.startsWith('private-')) {
    throw InvalidChannelNameException('Private channel name must start with "private-" prefix', channelName);
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelName.length > 200) {
    throw InvalidChannelNameException('Channel name cannot exceed 200 characters', channelName);
  }

  final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
  if (invalidChars.hasMatch(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}

/// Validates that a channel name is a valid presence channel name.
///
/// Presence channels must start with the "presence-" prefix.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid presence channel name.
void validatePresenceChannelName(String channelName) {
  if (channelName.isEmpty) {
    throw InvalidChannelNameException('Channel name cannot be empty', channelName);
  }

  if (!channelName.startsWith('presence-')) {
    throw InvalidChannelNameException('Presence channel name must start with "presence-" prefix', channelName);
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelName.length > 200) {
    throw InvalidChannelNameException('Channel name cannot exceed 200 characters', channelName);
  }

  final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
  if (invalidChars.hasMatch(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}

/// Validates that a channel name is a valid encrypted channel name.
///
/// Encrypted channels must start with the "private-encrypted-" prefix.
/// They combine private channel authentication with end-to-end encryption.
///
/// [channelName] The channel name to validate.
///
/// Throws [InvalidChannelNameException] if the channel name is not a valid encrypted channel name.
void validateEncryptedChannelName(String channelName) {
  if (channelName.isEmpty) {
    throw InvalidChannelNameException('Channel name cannot be empty', channelName);
  }

  if (!channelName.startsWith('private-encrypted-')) {
    throw InvalidChannelNameException('Encrypted channel name must start with "private-encrypted-" prefix', channelName);
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelName.length > 200) {
    throw InvalidChannelNameException('Channel name cannot exceed 200 characters', channelName);
  }

  final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
  if (invalidChars.hasMatch(channelName)) {
    throw InvalidChannelNameException(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed',
      channelName,
    );
  }
}
