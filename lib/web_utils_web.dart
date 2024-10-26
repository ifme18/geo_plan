import 'dart:html' as html;

dynamic getBlob(List<int> bytes, String mimeType) =>
    html.Blob([bytes], mimeType);
dynamic getUrl() => html.Url;
dynamic getAnchorElement(String? href) => html.AnchorElement(href: href);
void revokeObjectUrl(dynamic url) => html.Url.revokeObjectUrl(url);