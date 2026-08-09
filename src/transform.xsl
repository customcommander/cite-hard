<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:csl="http://purl.org/net/xbiblio/csl" xmlns:str="http://exslt.org/strings" extension-element-prefixes="str">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="stylename"/>

  <xsl:variable name="dialect">
    <xsl:variable name="locale" select="/csl:style/@default-locale"/>
    <xsl:choose>
      <!-- This project decision:
           If the style author has not set a default locale,
           this project will *always* default to 'en-US' -->
      <xsl:when test="not($locale)">en-US</xsl:when>
      <!-- If default locale set to a language,
           set it to the primary dialect, e.g. 'fr' -> 'fr-FR' -->
      <xsl:when test="$locale = 'af'">af-ZA</xsl:when>
      <xsl:when test="$locale = 'ar'">ar</xsl:when>
      <xsl:when test="$locale = 'bal'">bal-PK</xsl:when>
      <xsl:when test="$locale = 'bg'">bg-BG</xsl:when>
      <xsl:when test="$locale = 'brh'">brh-PK</xsl:when>
      <xsl:when test="$locale = 'ca'">ca-AD</xsl:when>
      <xsl:when test="$locale = 'cs'">cs-CZ</xsl:when>
      <xsl:when test="$locale = 'cy'">cy-GB</xsl:when>
      <xsl:when test="$locale = 'da'">da-DK</xsl:when>
      <xsl:when test="$locale = 'de'">de-DE</xsl:when>
      <xsl:when test="$locale = 'el'">el-GR</xsl:when>
      <xsl:when test="$locale = 'en'">en-US</xsl:when>
      <xsl:when test="$locale = 'es'">es-ES</xsl:when>
      <xsl:when test="$locale = 'et'">et-EE</xsl:when>
      <xsl:when test="$locale = 'eu'">eu</xsl:when>
      <xsl:when test="$locale = 'fa'">fa-IR</xsl:when>
      <xsl:when test="$locale = 'fi'">fi-FI</xsl:when>
      <xsl:when test="$locale = 'fr'">fr-FR</xsl:when>
      <xsl:when test="$locale = 'gl'">gl-ES</xsl:when>
      <xsl:when test="$locale = 'he'">he-IL</xsl:when>
      <xsl:when test="$locale = 'hi'">hi-IN</xsl:when>
      <xsl:when test="$locale = 'hr'">hr-HR</xsl:when>
      <xsl:when test="$locale = 'hu'">hu-HU</xsl:when>
      <xsl:when test="$locale = 'hy'">hy-AM</xsl:when>
      <xsl:when test="$locale = 'id'">id-ID</xsl:when>
      <xsl:when test="$locale = 'is'">is-IS</xsl:when>
      <xsl:when test="$locale = 'it'">it-IT</xsl:when>
      <xsl:when test="$locale = 'ja'">ja-JP</xsl:when>
      <xsl:when test="$locale = 'km'">km-KH</xsl:when>
      <xsl:when test="$locale = 'ko'">ko-KR</xsl:when>
      <xsl:when test="$locale = 'la'">la</xsl:when>
      <xsl:when test="$locale = 'lij'">lij-IT</xsl:when>
      <xsl:when test="$locale = 'lt'">lt-LT</xsl:when>
      <xsl:when test="$locale = 'lv'">lv-LV</xsl:when>
      <xsl:when test="$locale = 'mn'">mn-MN</xsl:when>
      <xsl:when test="$locale = 'ms'">ms-MY</xsl:when>
      <xsl:when test="$locale = 'nb'">nb-NO</xsl:when>
      <xsl:when test="$locale = 'nl'">nl-NL</xsl:when>
      <xsl:when test="$locale = 'nn'">nn-NO</xsl:when>
      <xsl:when test="$locale = 'pa'">pa-PK</xsl:when>
      <xsl:when test="$locale = 'pl'">pl-PL</xsl:when>
      <xsl:when test="$locale = 'pt'">pt-PT</xsl:when>
      <xsl:when test="$locale = 'ro'">ro-RO</xsl:when>
      <xsl:when test="$locale = 'ru'">ru-RU</xsl:when>
      <xsl:when test="$locale = 'sk'">sk-SK</xsl:when>
      <xsl:when test="$locale = 'sl'">sl-SI</xsl:when>
      <xsl:when test="$locale = 'sr'">sr-Latn-RS</xsl:when>
      <xsl:when test="$locale = 'sv'">sv-SE</xsl:when>
      <xsl:when test="$locale = 'th'">th-TH</xsl:when>
      <xsl:when test="$locale = 'tl'">tl-PH</xsl:when>
      <xsl:when test="$locale = 'tr'">tr-TR</xsl:when>
      <xsl:when test="$locale = 'uk'">uk-UA</xsl:when>
      <xsl:when test="$locale = 'vi'">vi-VN</xsl:when>
      <xsl:when test="$locale = 'zh'">zh-CN</xsl:when>
      <!-- Already a dialect -->
      <xsl:otherwise>
        <xsl:value-of select="$locale"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="dialect-primary">
    <xsl:choose>
      <xsl:when test="$dialect = 'de-AT'">de-DE</xsl:when>
      <xsl:when test="$dialect = 'de-CH'">de-DE</xsl:when>
      <xsl:when test="$dialect = 'en-GB'">en-US</xsl:when>
      <xsl:when test="$dialect = 'es-CL'">es-ES</xsl:when>
      <xsl:when test="$dialect = 'es-MX'">es-ES</xsl:when>
      <xsl:when test="$dialect = 'fr-CA'">fr-FR</xsl:when>
      <xsl:when test="$dialect = 'pt-BR'">pt-PT</xsl:when>
      <xsl:when test="$dialect = 'sr-Cyrl-RS'">sr-Latn-RS</xsl:when>
      <xsl:when test="$dialect = 'zh-TW'">zh-CN</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$dialect"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- e.g. 'en-US' -> 'en' -->
  <xsl:variable name="lang">
    <xsl:value-of select="str:tokenize($dialect, '-')[1]"/>
  </xsl:variable>

  <xsl:variable name="dialect-locale-doc"         select="document(concat('../vendor/locales/locales-', $dialect, '.xml'))"/>
  <xsl:variable name="dialect-primary-locale-doc" select="document(concat('../vendor/locales/locales-', $dialect-primary, '.xml'))"/>
  <xsl:variable name="dialect-default-locale-doc" select="document('../vendor/locales/locales-en-US.xml')"/>

  <xsl:template match="/csl:style">
    goog.module('citehard.styles.uncompiled');

    const Processor = goog.require('citehard.Processor');    

    const lib = goog.require('citehard.lib');

    <!-- macro functions -->
    <xsl:for-each select="csl:macro">
      <xsl:sort select="@name"/>

      function <xsl:apply-templates select="." mode="name"/>(reference) {
        return [
          <xsl:for-each select="*">
            <xsl:apply-templates select="."/>,
          </xsl:for-each>
        ];
      }
    </xsl:for-each>

    globalThis['cite-hard.styles.<xsl:value-of select="$stylename"/>'] = new Processor({
      cite: function _cite(reference) {
        return [
        <xsl:for-each select="csl:citation/csl:layout/*">
          <xsl:apply-templates select="."/>,
        </xsl:for-each>
        ];
      },

      citation: () => 'TODO',

      bibliography: function _bibliography() {
        return [
          <xsl:for-each select="csl:bibliography/csl:layout/*">
            <xsl:apply-templates select="."/>,
          </xsl:for-each>    
        ];
      }
    });
  </xsl:template>

  <xsl:template match="csl:*[@prefix or @suffix]" mode="affixes">
    <xsl:param name="next"/>
    [
      lib.wrap,
      {prefix: `<xsl:value-of select="@prefix"/>`, suffix: `<xsl:value-of select="@suffix"/>`},
      <xsl:value-of select="$next"/>
    ]
  </xsl:template>

  <xsl:template match="csl:*[not(@prefix) and not(@suffix)]" mode="affixes">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <xsl:template match="csl:*[@delimiter]" mode="delimiter">
    <xsl:param name="next"/>
    [
      lib.join,
      {delimiter:`<xsl:value-of select="@delimiter"/>`},
      <xsl:value-of select="$next"/>
    ]
  </xsl:template>

  <xsl:template match="csl:*[not(@delimiter)]" mode="delimiter">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <xsl:template match="csl:*">
    <xsl:apply-templates select="." mode="affixes">
      <xsl:with-param name="next">
        <xsl:apply-templates select="." mode="delimiter">
          <xsl:with-param name="next">
            [
              <xsl:apply-templates select="." mode="name"/>,
              <xsl:apply-templates select="." mode="options"/>,
              <xsl:apply-templates select="." mode="children"/>
            ]
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- DEFAULTS -->

  <xsl:template match="csl:*" mode="name">
    lib.<xsl:value-of select="str:replace(name(), '-', '_')"/>
  </xsl:template>

  <xsl:template match="csl:*" mode="options">
    null
  </xsl:template>

  <xsl:template match="csl:*" mode="children">
    <xsl:for-each select="*">
      <xsl:apply-templates select="."/>
      <xsl:if test="position() != last()">,</xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- IF/ELSE-IF -->

  <xsl:template match="csl:if | csl:else-if" mode="name">
    lib.test
  </xsl:template>

  <xsl:template match="csl:if | csl:else-if" mode="options">
    <xsl:variable name="mode">
      <xsl:choose>
        <xsl:when test="not(@match)">any</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@match"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    {
      mode: '<xsl:value-of select="$mode"/>',
      tests: [
        <xsl:for-each select="@*[name() != 'match']">
          [lib.test_<xsl:value-of select="str:replace(name(), '-', '_')"/>, '<xsl:value-of select="normalize-space(.)"/>'],
        </xsl:for-each>
      ]
    }
  </xsl:template>

  <!-- ELSE -->

  <xsl:template match="csl:else" mode="name">
    lib.T
  </xsl:template>

  <!-- NUMBER -->

  <xsl:template match="csl:number[@form = 'ordinal']" mode="name">
    lib.number_ordinal
  </xsl:template>

  <xsl:template match="csl:number[@form = 'long-ordinal']" mode="name">
    lib.number_long_ordinal
  </xsl:template>

  <xsl:template match="csl:number[@form = 'roman']" mode="name">
    lib.number_roman
  </xsl:template>

  <xsl:template match="csl:number[not(@form) or @form = 'numeric']" mode="name">
    lib.number_numeric
  </xsl:template>

  <xsl:template match="csl:number" mode="options">
    {name: `<xsl:value-of select="@variable"/>`}
  </xsl:template>

  <!-- TEXT
       For <text macro="..."> see MACRO section -->

  <xsl:template match="csl:text[@variable]" mode="name">
    lib.variable
  </xsl:template>

  <xsl:template match="csl:text[@variable]" mode="options">
    <xsl:variable name="form">
      <xsl:choose>
        <xsl:when test="not(@form)">long</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@form"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    {name: `<xsl:value-of select="@variable"/>`, form: '<xsl:value-of select="$form"/>'}
  </xsl:template>

  <xsl:template match="csl:text[@term]" mode="name">
    lib.term
  </xsl:template>

  <xsl:template match="csl:text[@term]" mode="options">
    {value: <xsl:apply-templates select="." mode="l10n"/>}
  </xsl:template>

  <xsl:template match="csl:text[@value]" mode="name">
    lib.value
  </xsl:template>

  <xsl:template match="csl:text[@value]" mode="options">
    {value: `<xsl:value-of select="@value"/>`}
  </xsl:template>

  <!-- MACRO / TEXT calling macro  -->
  
  <xsl:template match="csl:macro | csl:text[@macro]" mode="name">
    macro_<xsl:value-of select="str:replace(concat(@name, @macro), '-', '_')"/>
  </xsl:template>

  <!-- L10N -->

  <xsl:template match="csl:locale">
    <xsl:param name="name"/>
    <xsl:param name="form"/>
    <xsl:param name="plural"/>

    <xsl:variable name="term" select="csl:terms/csl:term[@name = $name and (@form = $form or not(@form))]"/>

    <xsl:choose>
      <xsl:when test="$term and $plural = 'true'">`<xsl:value-of select="$term/csl:multiple"/>`</xsl:when>
      <xsl:when test="$term and $term/csl:single">`<xsl:value-of select="$term/csl:single"/>`</xsl:when>
      <xsl:when test="$term">`<xsl:value-of select="$term/text()"/>`</xsl:when>        
      <xsl:otherwise>null</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Implements locale fallback logic -->
  <xsl:template match="csl:text[@term]" mode="l10n">
    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-1">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[@xml:lang = $dialect]">
          <xsl:apply-templates select="/csl:style/csl:locale[@xml:lang = $dialect]">
            <xsl:with-param name="name"   select="@term"/>
            <xsl:with-param name="form"   select="@form"/>
            <xsl:with-param name="plural" select="@plural"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>null</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-2">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[@xml:lang = $lang]">
          <xsl:apply-templates select="/csl:style/csl:locale[@xml:lang = $lang]">
            <xsl:with-param name="name"   select="@term"/>
            <xsl:with-param name="form"   select="@form"/>
            <xsl:with-param name="plural" select="@plural"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>null</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-3">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[not(@xml:lang)]">
          <xsl:apply-templates select="/csl:style/csl:locale[not(@xml:lang)]">
            <xsl:with-param name="name"   select="@term"/>
            <xsl:with-param name="form"   select="@form"/>
            <xsl:with-param name="plural" select="@plural"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>null</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="attempt-4">
      <xsl:apply-templates select="$dialect-locale-doc">
        <xsl:with-param name="name"   select="@term"/>
        <xsl:with-param name="form"   select="@form"/>
        <xsl:with-param name="plural" select="@plural"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="attempt-5">
      <xsl:apply-templates select="$dialect-primary-locale-doc">
        <xsl:with-param name="name"   select="@term"/>
        <xsl:with-param name="form"   select="@form"/>
        <xsl:with-param name="plural" select="@plural"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="attempt-6">
      <xsl:apply-templates select="$dialect-default-locale-doc">
        <xsl:with-param name="name"   select="@term"/>
        <xsl:with-param name="form"   select="@form"/>
        <xsl:with-param name="plural" select="@plural"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:value-of select="$attempt-1"/> ??
    <xsl:value-of select="$attempt-2"/> ??
    <xsl:value-of select="$attempt-3"/> ??
    <xsl:value-of select="$attempt-4"/> ??
    <xsl:value-of select="$attempt-5"/> ??
    <xsl:value-of select="$attempt-6"/> ??
                                        ''
  </xsl:template>


</xsl:stylesheet>
