<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:math="http://exslt.org/math"
    extension-element-prefixes="exsl date math">

<xsl:import href="./mathbook-html.xsl" />

<!-- Intend output for rendering by browsers-->
<xsl:output method="html" indent="yes"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in   xsl/mathbook-common.html -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<xsl:template match="/mathbook">
    <xsl:apply-templates mode="chunk" />
</xsl:template>

<!-- File wrap -->
<!-- Per file setup, macros, css, in/out SMC mode -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="url"><xsl:apply-templates select="." mode="url" /></xsl:variable>
    <exsl:document href="{$url}" method="html">
        <!-- CSS to hidden executable cell -->
        <xsl:call-template name="css-load" />
        <!-- Start in HTML mode -->
        <xsl:apply-templates select="." mode="inputbegin-execute" />
        <xsl:text>%html&#xa;</xsl:text>
        <xsl:text>\(</xsl:text>
        <xsl:value-of select="/mathbook/docinfo/macros" />
        <xsl:text>\)</xsl:text>
        <!-- top nav bar -->
        <xsl:apply-templates select="." mode="crude-nav-bar" />
        <!-- now the guts -->
        <xsl:copy-of select="$content" />
        <!-- fall out of SMC mode -->
        <xsl:apply-templates select="." mode="inputoutput" />
        <xsl:apply-templates select="." mode="outputend" />
        <!-- bottom nav bar -->
        <xsl:apply-templates select="." mode="crude-nav-bar" />
    </exsl:document>
</xsl:template>

<!-- Content wrap -->
<!-- per structural node: the whole page, or subsidiary -->
<!-- TODO: identical to HTML???? -->
<xsl:template match="*" mode="content-wrap">
    <xsl:param name="content" />
    <xsl:variable name="ident"><xsl:apply-templates select="." mode="internal-id" /></xsl:variable>
    <!-- Assume we are in SMC HTML mode -->
    <section class="{local-name(.)}" id="{$ident}">
        <xsl:apply-templates select="." mode="section-header" />
    </section>  <!-- NOT enclosing content, messes up in/out of SMC mode -->

    <!-- now the guts -->
    <xsl:copy-of select="$content" />

    <!-- Hop out, back in, to SMC HTML mode -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>

<!-- Intermediate should use file-wrap and content-wrap, -->
<!-- we just style links a bit here, but a CSS load -->
<!-- could do this -->
<xsl:template match="*" mode="summary-nav">
    <xsl:apply-imports select="."/>
    <br />
    <br />
</xsl:template>

<!-- Locate the containing file, need *.sagews here                  -->
<!-- Maybe the file extension could be parameterized in mathbook-html.xsl -->
<xsl:template match="*" mode="filename">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <xsl:apply-templates select="." mode="internal-id" />
            <xsl:text>.sagews</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Could be improved by conditioning on empty URLs -->
<xsl:template match="*" mode="crude-nav-bar">
    <table width="90%">
        <tr>
            <td align="left">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="previous-tree-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Previous</xsl:text>
                </xsl:element>
            </td>
            <td align="center">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="up-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Up</xsl:text>
                </xsl:element>
            </td>
            <td align="right">
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <xsl:apply-templates select="." mode="next-tree-url" />
                    </xsl:attribute>
                    <xsl:attribute name="style">
                        <xsl:text>font-size: 200%;</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Next</xsl:text>
                </xsl:element>
            </td>
        </tr>
    </table>
</xsl:template>

<!-- An abstract named template accepts input text and output    -->
<!-- text, then wraps it in SMC syntax for an executable cell    -->
<!-- (But does not evaluate the cell, that is for the reader)    -->
<!-- [Next part seems broken, code remains to test later]        -->
<!-- We are careful not to hop in/out of HTML mode when there    -->
<!-- is a sequence of consecutive Sage elements (a likely event) -->
<xsl:template name="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <!-- Drop out of HTML mode if first in a run (or first in subdivision) -->
    <!-- <xsl:if test="not(local-name(preceding-sibling::*[1]) = 'sage')"> -->
        <xsl:apply-templates select="." mode="inputoutput" />
        <xsl:apply-templates select="." mode="outputend" />
    <!-- </xsl:if> -->
    <!-- Create a complete Sage cell region -->
    <xsl:apply-templates select="." mode="inputbegin" />
        <xsl:value-of select="$in" disable-output-escaping="yes" />
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start back in HTML mode, if last in a run (or last in subdivision) -->
    <!-- <xsl:if test="not(local-name(following-sibling::*[1]) = 'sage')"> -->
        <xsl:apply-templates select="." mode="inputbegin-execute" />
        <xsl:text>%html&#xa;</xsl:text>
    <!-- </xsl:if> -->
</xsl:template>

<!-- We bypass image creation and just let SMC -->
<!-- do the job with an executable cell        -->
<xsl:template match="image[child::sageplot]">
    <xsl:apply-templates select="sageplot" />
</xsl:template>

<xsl:template match="sageplot">
    <!-- Drop out of HTML mode -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Create a complete Sage cell region -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%hide&#xa;</xsl:text>
    <xsl:call-template name="sanitize-code">
        <xsl:with-param name="raw-code" select="." />
    </xsl:call-template>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start back in HTML mode -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>

<!-- TODO: sage-display-only abstract template needed -->

<!-- Override wrapper for SVG images        -->
<!-- SMC treates the object tag badly,      -->
<!-- so we just use an img tag (with alt)   -->
<!-- Template expects a fallback flag,      -->
<!-- but this is just to support Sage 3D    -->
<!-- and we just do "sageplot" straightaway -->
<xsl:template match="*" mode="svg-wrapper">
    <xsl:param name="png-fallback" />
    <xsl:element name="img">
        <xsl:attribute name="style">width:60%; margin:auto;</xsl:attribute>
        <xsl:attribute name="src">
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select=".." mode="internal-id" />
            <xsl:text>.svg</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="../description" />
    </xsl:element>
</xsl:template>

<!-- CSS -->
<xsl:template name="css-load">
    <!-- Load CSS files                                -->
    <!-- A hidden cell, typically at the top of a page -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%hide&#xa;</xsl:text>
    <xsl:text>load("mathbook-content.css")&#xa;</xsl:text>
    <xsl:text>load("mathbook-add-on.css")&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Blend background color for MathJax display math -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
    <xsl:element name="style">
        <xsl:text>.MathJax_SVG_Display {background-color: inherit;}</xsl:text>
    </xsl:element>
    <xsl:apply-templates select="." mode="inputoutput" />
    <xsl:apply-templates select="." mode="outputend" />
</xsl:template>

<!-- ########################## -->
<!-- SageMathCloud Cell Markers -->
<!-- ########################## -->

<!-- Version 4 UUID -->
<!-- Improvements:                     -->
<!-- Use EXSLT random:random-sequence  -->
<!--   (1) Get a random number         -->
<!--   (2) Get content id of object    -->
<!--   (3) Mix to a new seed           -->
<!--   (4) Generate sequence and adorn -->
<!-- idpXXXXXXXX (universal format?)   -->
<!-- <xsl:value-of select="substring(generate-id(.), 4, 8)" /> -->
<xsl:template match="*" mode="uuid">
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 5 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 6 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 7 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 8 -->
    <xsl:text>-</xsl:text>
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:text>4</xsl:text> <!-- Version 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:text>a</xsl:text> <!-- Variant: leading bits 10 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:text>-</xsl:text>
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 3 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 4 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 5 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 6 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 7 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 8 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 9 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 0 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 1 -->
    <xsl:call-template name="random-hex-digit" /> <!-- 2 -->
</xsl:template>

<xsl:template name="random-hex-digit">
    <xsl:variable name="digit" select="floor(16*math:random())" />
    <xsl:choose>
        <xsl:when test="10 > $digit">
            <xsl:value-of select="$digit" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$digit = 10">a</xsl:when>
                <xsl:when test="$digit = 11">b</xsl:when>
                <xsl:when test="$digit = 12">c</xsl:when>
                <xsl:when test="$digit = 13">d</xsl:when>
                <xsl:when test="$digit = 14">e</xsl:when>
                <xsl:when test="$digit = 15">f</xsl:when>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- SMC codes for blocking cells          -->
<!-- carriage returns are carefully placed -->
<xsl:template match="*" mode="inputbegin">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "x" code after UUID to execute -->
<xsl:template match="*" mode="inputbegin-execute">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>x</xsl:text>
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- "i" code after UUID to hide -->
<xsl:template match="*" mode="inputbegin-hide">
    <xsl:text>&#xFE20;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>i</xsl:text>
    <xsl:text>&#xFE20;&#xa;</xsl:text>
</xsl:template>

<!-- End an input cell and begin subsequent output cell -->
<xsl:template match="*" mode="inputoutput">
    <xsl:text>&#xa;&#xFE21;</xsl:text>
    <xsl:apply-templates select="." mode="uuid" />
    <xsl:text>&#xFE21;</xsl:text>
</xsl:template>

<!-- End an output cell -->
<xsl:template match="*" mode="outputend">
    <xsl:text>&#xFE21;&#xa;</xsl:text>
</xsl:template>

<!-- We like to keep HTML cells short and manageable -->
<!-- So we frequently drop out of HTML mode,         -->
<!-- only to instantly restart back in HTML mode     -->
<!-- This presumes                                   -->
<!-- (1) Page begins in HTML mode                    -->
<!-- (2) Page ending concludes HTML mode             -->
<!-- (3) Sage cells drop out/in properly             -->
<xsl:template match="*" mode="html-break">
    <!-- End input, begin output -->
    <xsl:apply-templates select="." mode="inputoutput" />
    <!-- End ouput               -->
    <xsl:apply-templates select="." mode="outputend" />
    <!-- Start new HTML cell     -->
    <xsl:apply-templates select="." mode="inputbegin-execute" />
    <xsl:text>%html&#xa;</xsl:text>
</xsl:template>



</xsl:stylesheet>