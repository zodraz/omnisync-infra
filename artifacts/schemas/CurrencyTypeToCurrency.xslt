<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dm="http://azure.workflow.datamapper" xmlns:ef="http://azure.workflow.datamapper.extensions" xmlns="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="xsl xs math dm ef" version="3.0" expand-text="yes">
  <xsl:output indent="yes" media-type="text/json" method="text" omit-xml-declaration="yes" />
  <xsl:template match="/">
    <xsl:variable name="xmlinput" select="json-to-xml(/)" />
    <xsl:variable name="xmloutput">
      <xsl:apply-templates select="$xmlinput" mode="azure.workflow.datamapper" />
    </xsl:variable>
    <xsl:value-of select="xml-to-json($xmloutput,map{'indent':true()})" />
  </xsl:template>
  <xsl:template match="/" mode="azure.workflow.datamapper">
    <map>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='Id'])) = 'null'">
          <null key="SalesForceId" />
        </xsl:when>
        <xsl:otherwise>
          <string key="SalesForceId">{/*/*[@key='Id']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='IsoCode'])) = 'null'">
          <null key="CurrencyCode" />
        </xsl:when>
        <xsl:otherwise>
          <string key="CurrencyCode">{/*/*[@key='IsoCode']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='ConversionRate'])) = 'null'">
          <null key="ConversionRate" />
        </xsl:when>
        <xsl:otherwise>
          <number key="ConversionRate">{/*/*[@key='ConversionRate']}</number>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='IsActive'])) = 'True'">
           <boolean key="IsDeleted">false</boolean>
        </xsl:when>
        <xsl:otherwise>
           <boolean key="IsDeleted">true</boolean>  
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='CreatedDate'])) = 'null'">
          <null key="CreatedDate" />
        </xsl:when>
        <xsl:otherwise>
          <string key="CreatedDate">{/*/*[@key='CreatedDate']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='LastModifiedDate'])) = 'null'">
          <null key="UpdatedDate" />
        </xsl:when>
        <xsl:otherwise>
          <string key="UpdatedDate">{/*/*[@key='LastModifiedDate']}</string>
        </xsl:otherwise>
      </xsl:choose>
    </map>
  </xsl:template>
</xsl:stylesheet>