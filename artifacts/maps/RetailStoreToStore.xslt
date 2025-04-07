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
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='AccountId'])) = 'null'">
          <null key="CustomerKey" />
        </xsl:when>
        <xsl:otherwise>
          <string key="CustomerKey">{/*/*[@key='AccountId']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='StoreTypeID__c'])) = 'null'">
          <null key="StoreTypeID" />
        </xsl:when>
        <xsl:otherwise>
          <number key="StoreTypeID">{/*/*[@key='StoreTypeID__c']}</number>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='StoreType'])) = 'null'">
          <null key="StoreType" />
        </xsl:when>
        <xsl:otherwise>
          <string key="StoreType">{/*/*[@key='StoreType']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='Name'])) = 'null'">
          <null key="StoreName" />
        </xsl:when>
        <xsl:otherwise>
          <string key="StoreName">{/*/*[@key='Name']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='Name'])) = 'null'">
          <null key="StoreDescription" />
        </xsl:when>
        <xsl:otherwise>
          <string key="StoreDescription">{/*/*[@key='Name']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='Phone__c'])) = 'null'">
          <null key="StorePhone" />
        </xsl:when>
        <xsl:otherwise>
          <string key="StorePhone">{/*/*[@key='Phone__c']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='Fax__c'])) = 'null'">
          <null key="StoreFax" />
        </xsl:when>
        <xsl:otherwise>
          <string key="StoreFax">{/*/*[@key='Fax__c']}</string>
        </xsl:otherwise>
      </xsl:choose>
      <string key="AddressLine1">{replace(concat(/*/*[@key='Street'], ' ', /*/*[@key='City'], ' ', /*/*[@key='State'], ' ', /*/*[@key='Country']), '(^\s+|\s+$)', '')}</string>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='EmployeeCount__c'])) = 'null'">
          <null key="EmployeeCount" />
        </xsl:when>
        <xsl:otherwise>
          <number key="EmployeeCount">{/*/*[@key='EmployeeCount__c']}</number>
        </xsl:otherwise>
      </xsl:choose>
      <string key="Latitude">{string(/*/*[@key='Latitude'])}</string>
      <string key="Longitude">{string(/*/*[@key='Longitude'])}</string>
      <xsl:choose>
        <xsl:when test="local-name-from-QName(node-name(/*/*[@key='IsDeleted'])) = 'null'">
          <null key="IsDeleted" />
        </xsl:when>
        <xsl:otherwise>
          <boolean key="IsDeleted">{/*/*[@key='IsDeleted']}</boolean>
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