<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:csl="http://purl.org/net/xbiblio/csl"
    xmlns:str="http://exslt.org/strings"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="str exsl">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:key name="k-term" match="csl:text[@term]" use="concat(@term, '|', @form)"/>
  <xsl:key name="k-name-token" match="token" use="concat(text(), '|', @form)"/>

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

    const lib = goog.require('citehard.lib');

    const Processor = goog.require('citehard.Processor');

    const locales = {};

    <!-- All the terms called via <csl:text term="..."> -->
    <xsl:for-each select="//csl:text[@term][generate-id() = generate-id(key('k-term', concat(@term, '|', @form))[1])]">
      <xsl:sort select="@term"/>
      locales.<xsl:value-of select="translate(concat(@term, '__', @form), '- ', '__')"/> =
      <xsl:call-template name="l10n">
        <xsl:with-param name="name"   select="@term"/>
        <xsl:with-param name="form"   select="@form"/>
      </xsl:call-template>;
    </xsl:for-each>

    <!-- All the terms called via <csl:names />  -->    
    <xsl:variable name="name-tokens-rtf">
      <xsl:for-each select="//csl:names[csl:label]">
        <xsl:variable name="form" select="csl:label/@form"/>
        <xsl:choose>
          <xsl:when test="@variable = 'editor translator'">
            <token form="{$form}">editortranslator</token>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="str:tokenize(normalize-space(@variable), ' ')">
              <token form="{$form}"><xsl:value-of select="."/></token>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="name-tokens" select="exsl:node-set($name-tokens-rtf)/token"/>

    <xsl:for-each select="$name-tokens[generate-id() = generate-id(key('k-name-token', concat(text(), '|', @form))[1])]">
      <xsl:sort select="."/>
      locales.<xsl:value-of select="translate(concat(text(), '__', @form), '- ', '__')"/> = 
      <xsl:call-template name="l10n">
        <xsl:with-param name="name"   select="."/>
        <xsl:with-param name="form"   select="@form"/>
      </xsl:call-template>;
    </xsl:for-each>

    <xsl:for-each select="csl:macro">
      <xsl:sort select="@name"/>
      function macro_<xsl:value-of select="translate(@name, '-', '_')"/>(ctx, reference) {
        return (<xsl:apply-templates select="*[position() = 1]" mode="function-call" />);
      }
    </xsl:for-each>

    globalThis['cite-hard.styles.<xsl:value-of select="$stylename"/>'] = new Processor({
      cite: function _cite(ctx, reference) {
        return (<xsl:apply-templates select="csl:citation/csl:layout" mode="function-call"/>);
      },

      citation: () => 'TODO',

      bibliography: function _bibliography(ctx, reference) {
        return (<xsl:apply-templates select="csl:bibliography/csl:layout" mode="function-call"/>);
      }
    });
  </xsl:template>

  <!-- AFFIXES -->

  <xsl:template match="csl:*[@prefix or @suffix]" mode="affixes">
    <xsl:param name="next"/>
    lib.wrap(
      `<xsl:value-of select="@prefix"/>`,
      `<xsl:value-of select="@suffix"/>`,
      <xsl:value-of select="$next"/>
    )
  </xsl:template>

  <xsl:template match="csl:*[not(@prefix or @suffix)]" mode="affixes">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <!-- FORMATTING -->

  <xsl:template match="csl:*[@font-style or @font-variant or @font-weight or @text-decoration or @vertical-align]" mode="formatting">
    <xsl:param name="next"/>
    lib.format(
      '<xsl:value-of select="@font-style"/>',
      '<xsl:value-of select="@font-variant"/>',
      '<xsl:value-of select="@font-weight"/>',
      '<xsl:value-of select="@text-decoration"/>',
      '<xsl:value-of select="@vertical-align"/>',
      <xsl:value-of select="$next"/>
    )
  </xsl:template>

  <xsl:template match="csl:*[not(@font-style or @font-variant or @font-weight or @text-decoration or @vertical-align)]" mode="formatting">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <!-- DISPLAY -->

  <xsl:template match="csl:*[@display]" mode="display">
    <xsl:param name="next"/>
    lib.display(
      new lib.DisplayAttrs('<xsl:value-of select="@display"/>'),
      <xsl:value-of select="$next"/>
    )
  </xsl:template>

  <xsl:template match="csl:*[not(@display)]" mode="display">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <!-- TEXT-CASE -->

  <xsl:template match="csl:*[@text-case]" mode="text-case">
    <xsl:param name="next"/>
    lib.case_<xsl:value-of select="translate(@text-case, '-', '_')"/>(
      <xsl:value-of select="$next"/>
    )
  </xsl:template>

  <xsl:template match="csl:*[not(@text-case)]" mode="text-case">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>

  <!-- STRIP PERIODS -->

  <xsl:template match="csl:*[@strip-periods = 'true']" mode="strip-periods">
    <xsl:param name="next"/>
    lib.strip_periods(
      <xsl:value-of select="$next"/>
    )
  </xsl:template>

  <xsl:template match="csl:*[not(@strip-periods = 'true')]" mode="strip-periods">
    <xsl:param name="next"/>
    <xsl:value-of select="$next"/>
  </xsl:template>


  <!-- NODE -> JS -->

  <xsl:template match="csl:label[name(..) = 'names']">
    /* disable output label */
  </xsl:template>

  <xsl:template match="csl:*">
    <xsl:apply-templates select="." mode="display">
      <xsl:with-param name="next">
        <xsl:apply-templates select="." mode="affixes">
          <xsl:with-param name="next">
            <xsl:apply-templates select="." mode="formatting">
              <xsl:with-param name="next">
                <xsl:apply-templates select="." mode="text-case">
                  <xsl:with-param name="next">
                    <xsl:apply-templates select="." mode="strip-periods">
                      <xsl:with-param name="next">
                        <xsl:apply-templates select="." mode="function-call"/>
                      </xsl:with-param>
                    </xsl:apply-templates>
                  </xsl:with-param>
                </xsl:apply-templates>
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- DEFAULTS -->

  <xsl:template match="csl:*" mode="function-call">
    lib.<xsl:value-of select="translate(name(), '-', '_')"/>('TODO')
  </xsl:template>

  <!-- GROUP -->

  <xsl:template match="csl:group" mode="function-call">
    lib.group(
      [
      <xsl:for-each select="*">
        <xsl:apply-templates select="."/>
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
      ]
      <xsl:if test="@delimiter">
      , `<xsl:value-of select="@delimiter"/>`
      </xsl:if>
    )
  </xsl:template>

  <!-- LAYOUT -->

  <xsl:template match="csl:layout" mode="function-call">
    lib.layout(ctx, reference, [
      <xsl:for-each select="*">
        <xsl:apply-templates select="."/>
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
    ])
  </xsl:template>


  <!-- CHOOSE -->

  <xsl:template match="csl:choose" mode="function-call">
    lib.choose(
      <xsl:for-each select="csl:if | csl:else-if">
        <xsl:apply-templates select="." mode="bool-condition"/>
          ? <xsl:apply-templates select="." mode="function-call"/>
          : /* next run or else/null */
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="csl:else">
          <xsl:apply-templates select="csl:else" mode="function-call"/>
        </xsl:when>
        <xsl:otherwise>null</xsl:otherwise>
      </xsl:choose>
    )
  </xsl:template>

  <xsl:template match="csl:if | csl:else-if" mode="bool-condition">
    <xsl:variable name="condition">
      <xsl:choose>
        <xsl:when test="@match = 'any'">any</xsl:when>
        <xsl:when test="@match = 'none'">none</xsl:when>
        <xsl:otherwise>all</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="js-operator">
      <xsl:choose>
        <xsl:when test="$condition = 'any'">||</xsl:when>
        <xsl:otherwise>&amp;&amp;</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="lib-condition-function" select="concat('lib.test_', $condition)"/>

    (
    <xsl:for-each select="@*[not(name() = 'match')]">
      <xsl:choose>
        <xsl:when test="name() = 'is-numeric'">
          <xsl:value-of select="$lib-condition-function"/>(lib.test_is_numeric(reference), '<xsl:value-of select="."/>')
        </xsl:when>
        <xsl:when test="name() = 'is-uncertain-date'">
          <xsl:value-of select="$lib-condition-function"/>(lib.test_is_uncertain_date(reference), '<xsl:value-of select="."/>')
        </xsl:when>
        <xsl:when test="name() = 'type'">
          <xsl:value-of select="$lib-condition-function"/>(lib.test_type(reference), '<xsl:value-of select="normalize-space(.)"/>')
        </xsl:when>
        <xsl:when test="name() = 'variable'">
          <xsl:value-of select="$lib-condition-function"/>(lib.test_variable(reference), '<xsl:value-of select="."/>')
        </xsl:when>
        <xsl:when test="name() = 'locator'">
          <xsl:value-of select="$lib-condition-function"/>(lib.test_locator(reference), '<xsl:value-of select="."/>')
        </xsl:when>
        <xsl:otherwise>'TODO:<xsl:value-of select="name()"/>'</xsl:otherwise>
      </xsl:choose>
      <xsl:if test="not(position() = last())">
        <xsl:value-of select="$js-operator"/>
      </xsl:if>
    </xsl:for-each>
    )
  </xsl:template>

  <!-- IF/ELSE-IF -->

  <xsl:template match="csl:if | csl:else-if | csl:else" mode="function-call">
    <xsl:choose>
      <xsl:when test="count(*) = 1">
        <xsl:apply-templates select="*[1]" mode="function-call"/>
      </xsl:when>
      <xsl:otherwise>
        lib.concat([
          <xsl:for-each select="*">
            <xsl:apply-templates select="." mode="function-call" />
            <xsl:if test="not(position() = last())">,</xsl:if>
          </xsl:for-each>
        ])
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- NAMES -->

  <xsl:template match="csl:name-group" mode="function-call">
    lib.name_group(
      <xsl:for-each select="*">
        <xsl:apply-templates select="." />
        <xsl:if test="not(position() = last())">,</xsl:if>
      </xsl:for-each>
    )
  </xsl:template>

  <xsl:template match="csl:name-group/csl:label" mode="function-call">
  </xsl:template>

  <xsl:template match="csl:names" mode="function-call">

    <xsl:variable name="label-before" select="boolean(csl:label[following-sibling::csl:name])"/> 
    <xsl:variable name="label-after"  select="boolean(csl:label[not(following-sibling::csl:name)])"/>

    <xsl:variable name="src" select="csl:label | csl:name"/>

    <xsl:variable name="name-groups">
      <xsl:for-each select="str:tokenize(normalize-space(@variable), ' ')">
        <xsl:element name="csl:name-group" namespace="http://purl.org/net/xbiblio/csl">
          <xsl:if test="$label-before">
            
          </xsl:if>
          <xsl:if test="$label-after"></xsl:if>
        </xsl:element>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="has-label" select="csl:label"/>
    <xsl:variable name="label-position">
      <xsl:choose>
        <xsl:when test="csl:label[following-sibling::csl:name]">before</xsl:when>
        <xsl:otherwise>after</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    lib.names(
      [
      <xsl:for-each select="str:tokenize(normalize-space(@variable), ' ')">
        lib.name(reference['<xsl:value-of select="."/>'], {
          
        })
        <xsl:if test="not(position() = last())">,</xsl:if>
      </xsl:for-each>
      ]
      <xsl:if test="@delimiter">
      , `<xsl:value-of select="@delimiter"/>`
      </xsl:if>
    )
  </xsl:template>

  <!-- NUMBER -->

  <xsl:template match="csl:number[@form = 'ordinal']" mode="function-call">
    lib.number_ordinal(reference['<xsl:value-of select="@variable"/>'])
  </xsl:template>

  <xsl:template match="csl:number[@form = 'long-ordinal']" mode="function-call">
    lib.number_long_ordinal(reference['<xsl:value-of select="@variable"/>'])
  </xsl:template>

  <xsl:template match="csl:number[@form = 'roman']" mode="function-call">
    lib.number_roman(reference['<xsl:value-of select="@variable"/>'])
  </xsl:template>

  <xsl:template match="csl:number[not(@form) or @form = 'numeric']" mode="function-call">
    lib.number_numeric(reference['<xsl:value-of select="@variable"/>'])
  </xsl:template>

  <!-- TEXT
       For <text macro="..."> see MACRO section -->

  <xsl:template match="csl:text[@variable]" mode="function-call">
    lib.variable(
      <xsl:choose>
        <xsl:when test="@variable = 'container-title-short' or (@form = 'short' and @variable = 'container-title')">
          reference['container-title-short'] ?? reference['container-title']
        </xsl:when>
        <xsl:when test="@variable = 'title-short' or (@form = 'short' and @variable = 'title')">
          reference['title-short'] ?? reference['title']
        </xsl:when>
        <xsl:otherwise>
          reference['<xsl:value-of select="@variable"/>']
        </xsl:otherwise>
      </xsl:choose>
    )
  </xsl:template>

  <xsl:template match="csl:text[@term]" mode="function-call">
    lib.term(locales.<xsl:apply-templates select="." mode="l10n-var-name"/>)
  </xsl:template>

  <xsl:template match="csl:text[@value]" mode="function-call">
    lib.value(`<xsl:value-of select="@value"/>`)
  </xsl:template>

  <!-- MACRO / TEXT calling macro  -->
  
  <xsl:template match="csl:text[@macro]" mode="function-call">
    macro_<xsl:value-of select="translate(@macro, '-', '_')"/>(ctx, reference)
  </xsl:template>

  <!-- L10N -->

  <xsl:template match="csl:locale">
    <xsl:param name="type" select="'term'"/>
    <xsl:param name="name"/>
    <xsl:param name="form"/>

    <xsl:if test="$type = 'term'">
      <!-- Prefer an exact form match; only fall back to the unmarked
           term when no exact-form sibling exists, otherwise a name
           with both variants matches two nodes and document order
           silently wins. -->
      <xsl:variable name="has-exact-form" select="boolean(csl:terms/csl:term[@name = $name and @form = $form])"/>
      <xsl:variable name="term" select="csl:terms/csl:term[@name = $name and (@form = $form or (not(@form) and not($has-exact-form)))]"/>
      <xsl:choose>
        <xsl:when test="$term and $term/csl:multiple">
          [`<xsl:value-of select="$term/csl:single"/>`,`<xsl:value-of select="$term/csl:multiple"/>`]
        </xsl:when>
        <xsl:when test="$term">
          [`<xsl:value-of select="$term/text()"/>`]
        </xsl:when>        
        <xsl:otherwise>
          null
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="csl:text[@term]" mode="l10n-var-name">
    <xsl:value-of select="translate(concat(@term, '__', @form), '- ', '__')"/>
  </xsl:template>

  <xsl:template match="csl:text[@term]" mode="l10n">
    <xsl:call-template name="l10n">
      <xsl:with-param name="name" select="@term"/>
      <xsl:with-param name="form" select="@form"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Implements locale fallback logic -->
  <xsl:template name="l10n">
    <xsl:param name="name"/>
    <xsl:param name="form"/>
    <xsl:param name="plural"/>

    <!-- @form may be an empty node-set (attribute not present on the
         source element). Forwarding that as-is to csl:locale's $form
         param counts as "supplied", so its own 'long' default never
         kicks in. Resolve the effective form here instead. -->
    <xsl:variable name="effective-form">
      <xsl:choose>
        <xsl:when test="$form">
          <xsl:value-of select="$form"/>
        </xsl:when>
        <xsl:otherwise>long</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-1">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[@xml:lang = $dialect]">
          <xsl:apply-templates select="/csl:style/csl:locale[@xml:lang = $dialect]">
            <xsl:with-param name="name"   select="$name"/>
            <xsl:with-param name="form"   select="$effective-form"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          null
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-2">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[@xml:lang = $lang]">
          <xsl:apply-templates select="/csl:style/csl:locale[@xml:lang = $lang]">
            <xsl:with-param name="name"   select="$name"/>
            <xsl:with-param name="form"   select="$effective-form"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          null
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- read from style locale matching dialect -->
    <xsl:variable name="attempt-3">
      <xsl:choose>
        <xsl:when test="/csl:style/csl:locale[not(@xml:lang)]">
          <xsl:apply-templates select="/csl:style/csl:locale[not(@xml:lang)]">
            <xsl:with-param name="name"   select="$name"/>
            <xsl:with-param name="form"   select="$effective-form"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          null
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="attempt-4">
      <xsl:apply-templates select="$dialect-locale-doc">
        <xsl:with-param name="name"   select="$name"/>
        <xsl:with-param name="form"   select="$effective-form"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="attempt-5">
      <xsl:apply-templates select="$dialect-primary-locale-doc">
        <xsl:with-param name="name"   select="$name"/>
        <xsl:with-param name="form"   select="$effective-form"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="attempt-6">
      <xsl:apply-templates select="$dialect-default-locale-doc">
        <xsl:with-param name="name"   select="$name"/>
        <xsl:with-param name="form"   select="$effective-form"/>
      </xsl:apply-templates>
    </xsl:variable>

    (<xsl:value-of select="$attempt-1"/> ??

     <xsl:value-of select="$attempt-2"/> ??

     <xsl:value-of select="$attempt-3"/> ??

     <xsl:value-of select="$attempt-4"/> ??

     <xsl:value-of select="$attempt-5"/> ??

     <xsl:value-of select="$attempt-6"/> ??

     [""])
  </xsl:template>

</xsl:stylesheet>
