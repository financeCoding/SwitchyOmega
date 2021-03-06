/**
 * Matches if the bypass list [pattern] matches the URL. 
 * For the pattern syntax, see
 * <https://code.google.com/chrome/extensions/proxy.html#bypass_list>
 */
class BypassCondition extends Condition {
  final String conditionType = 'BypassCondition';
  
  String _pattern;
  String get pattern() => _pattern;
  void set pattern(String value) {
    _pattern = value;
    _cached = false;
  }
  
  bool _cached = false;
  HostWildcardCondition _hostWildcard;
  IpCondition _ip;
  String _matchScheme;
  UrlRegexCondition _urlRegex;
  
  /** Cache the charCode of "]" for greater speed. */
  static final int closeSquareBracketCode = 93;
  
  /** A special [pattern] which matches all [localHosts]. */
  static final String localPattern = '<local>';
  
  static final List<String> localHosts = const ["127.0.0.1", "[::1]", "localhost"];
  
  void _parsePattern() {
    var server = _pattern;
    if (server == localPattern) {
      _cached = true;
      return;
    }
    var parts = server.split('://');
    if (parts.length > 1) {
      _matchScheme = parts[0];
      server = parts[1];
    } else {
      _matchScheme = null;
    }
    parts = server.split('/');
    if (parts.length > 1) {
      _ip = new IpCondition(parts[0], Math.parseInt(parts[1]));
      _hostWildcard = null;
    } else {
      _urlRegex = null;
      _hostWildcard = null;
      if (server.charCodeAt(server.length - 1) != closeSquareBracketCode) {
        var pos = server.lastIndexOf(':');
        if (pos >= 0) {
          var matchPort = server.substring(pos + 1);
          server = server.substring(0, pos);
          var serverRegex = shExp2RegExp(server);
          serverRegex = serverRegex.substring(1, serverRegex.length - 1);
          _urlRegex = new UrlRegexCondition(
            @'^[^:]+:/*' '$serverRegex:$matchPort');
        }
      }
      if (_urlRegex == null && server != '*') {
        _hostWildcard = new HostWildcardCondition(server);
      }
      _ip = null;
    }
    _cached = true;
  }
  
  bool match(String url, String host, String scheme, Date datetime) {
    if (!_cached) _parsePattern();
    if (pattern == localPattern) return localHosts.indexOf(host) >= 0;
    if (_matchScheme != null && _matchScheme != scheme) return false;
    if (_urlRegex != null && !_urlRegex.matchUrl(url, scheme)) return false;
    if (_hostWildcard != null && !_hostWildcard.matchHost(host)) return false;
    if (_ip != null && !_ip.matchHost(host)) return false;
    return true;
  }
  
  void writeTo(CodeWriter w) {
    if (!_cached) _parsePattern();
    if (pattern == localPattern) {
      for (var i = 0; i < localHosts.length; i++) {
        w.inline('host === ${JSON.stringify(localHosts[i])}');
        if (i != localHosts.length - 1) w.code(' || ');
      }
      return;
    }
    if (_matchScheme != null) {
      w.inline('scheme === ${JSON.stringify(_matchScheme)} && ');
    }
    if (_urlRegex != null) {
      _urlRegex.writeTo(w);
    } else if (_hostWildcard != null) {
      _hostWildcard.writeTo(w);
    } else if (_ip != null) {
      _ip.writeTo(w);
    } else {
      w.inline('true');
    }
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory BypassCondition.fromPlain(Map<String, Object> p, [Object config]) {
    return new BypassCondition(p['pattern']);
  }
  
  BypassCondition([String pattern = '']) {
    this._pattern = pattern;
  }
}
