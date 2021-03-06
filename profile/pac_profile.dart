/**
 * A PAC profile selects the proxy by running a [pacScript].
 * If [pacUrl] is not null, the script is downloaded from [pacUrl].
 */
class PacProfile extends ScriptProfile {
  String get profileType() => 'PacProfile';
  
  String _pacUrl;
  String get pacUrl() => _pacUrl;
  void set pacUrl(String value) {
    if (value != null && value != _pacUrl) {
      pacScript = null;
    }
    _pacUrl = value;
  }
  
  String pacScript;

  String toScript() => this.pacScript;
  
  /**
   * Write a wrapper function around the [pacScript].
   */
  void writeTo(CodeWriter w) {
    w.code('function (url, host) {');
    
    w.newLine().raw(this.pacScript).newLine();
    
    w.code('return FindProxyForURL(url, host);');
    w.inline('}');
  }

  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    
    if (pacUrl != null) {
      p['pacUrl'] = this.pacUrl;
    } else {
      p['pacScript'] = this.pacScript;
    }
    
    return p;
  }
  
  
  PacProfile(String name) : super(name);
  
  factory PacProfile.fromPlain(Map<String, Object> p, [Object config]) {
    if (p['profileType'] == 'AutoDectProfile')
      return new AutoDetectProfile.fromPlain(p, config);
    var f = new PacProfile(p['name']);
    f.color = p['color'];
    var u = p['pacUrl'];
    if (u != null) {
      f.pacUrl = u;
    } else {
      f.pacScript = p['pacScript'];
    }
    return f;
  }
}
