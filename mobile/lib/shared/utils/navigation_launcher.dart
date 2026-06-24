import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';

/// Opens [place]'s location in Google Maps.
///
/// Prefers [Place.websiteUrl] (a `maps.app.goo.gl` share link). If that's
/// missing, falls back to a `google.com/maps/search` URL built from the
/// place's name and coordinates, which works without the Google Maps app
/// installed (opens in browser) and with it (deep-links into the app).
///
/// Shows a SnackBar via [context] if no map app/browser can handle the URL.
Future<void> openInGoogleMaps(BuildContext context, Place place) async {
  final url = place.websiteUrl != null && place.websiteUrl!.isNotEmpty
      ? place.websiteUrl!
      : 'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';

  final uri = Uri.parse(url);

  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open maps for ${place.name}')),
    );
  }
}
