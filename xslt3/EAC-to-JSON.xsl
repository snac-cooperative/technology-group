<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ead3="http://ead3.archivists.org/schema/"
    xmlns:eac="urn:isbn:1-931666-33-4" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:j="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="ead3 eac xs xlink"
    version="3.0">
    <!-- author(s): Mark Custer... you?  and you??? anyone else who wants to help! -->
    <!-- requires XSLT 3.0 -->
    <!-- tested with Saxon-HE 9.8.0.12 -->

    <xsl:output method="text" encoding="UTF-8"/>

    <!-- data mapping:
        https://docs.google.com/spreadsheets/d/1xUFwul4maRrDGzx_S4JGGoAwkLYzrpbOLIfjaaiwrLM/edit?usp=sharing
        
        map, array, string, number, boolean, null
        x within map.
    -->

    <!--  
        JSON to XML
    https://www.w3.org/TR/xpath-functions-31/schema-for-json.xsd
    -->

    <!-- 
        
    guiding princples / thoughts:
    any wrapper elements or elements that can repeat, convert to or create an array.
    attributes convert to and from JSON very nicely.... 
        but should skip xml:id and the like????
    we're assuming that this process should be able to convert ANY valid EAC record. 
    EAC is quite flexible (but sometimes it only appears that way, specifically with those wrapper elements and sections like structureOrGenealogy which lack unique structural elements)
    
    to think more about:
    1)
    repeatability is a bit annoying going from EAC's XML to JSON.
    you shouldn't have duplicate keys in JSON (although we could, since it's not prohibited),
    so in those cases of repeatability right now i'm opting to create an array
    with a new name for the element (even if there's only one).
    e.g. agencyName_array/agencyName
         languageDeclaration_array/languageDeclaration
         etc. 
       
    2)
    i'll probably need to write a transformation of this file to produce one for SNAC JSON, unless that data structure is altered considerably.
    ...but that would be easier than starting with a transformation that was only optimized for SNAC and then expanding that to support any EAC input.
    
    3) add support for eac-grp or not?  doesn't seem to be part of the official standard, but it it is in the Github repo.
    
    -->

    <!-- to do: 

        add an order/ordinal value for things like outline and p (since those can be mixed).
            e.g. "order": 1 
        
        combine, refactor, combine, repeat, etc. 
            (should just create templates for different json types: e.g. map, array within a map, etc.
            and reduce the size of this file considerably.)
        
        figure out what to do about empty elements.
            leave off, leave empty (current approach), or add NULL to the output?  
            
        do something about objectBinWrap?
         
        go over mapping spreadsheet again.
        
        write tests!
        
    -->

    <!-- 1) global parameters and variables -->
    <!-- could add a few options here based on the required need of the output.  e.g. optimized for snap; stripped of any XML like span; etc.-->
    
    <!-- 2) primary template section -->
 
    <xsl:template match="eac:eac-cpf">
        <xsl:variable name="xml">
            <xsl:call-template name="create-xml"/>
        </xsl:variable>
        <xsl:sequence
            select="$xml => xml-to-json() => parse-json() => 
            serialize(map{'method':'json','indent': true(),'use-character-maps': map{'/': '/'}})"/>  
    </xsl:template>
    
    <!-- here's where we create the XML document in order to convert it to JSON.
    somewhat specific to SNAC right now, since we're adding the "Constellation" value.-->
    <xsl:template name="create-xml">
        <j:map>
            <j:string key="dataType">Constellation</j:string>
            <xsl:apply-templates select="@xml:id|@xml:lang|@xml:base|*"/>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:multipleIdentities">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:cpfDescription[1]" mode="json-array"/>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:control">
        <!-- in order to keep the 3 attributes that can appear on the control element,
            i'm deviating from the current SNAC EAC to JSON mapping here.
        i can remove the "map" bit later if that's not desired-->
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:recordId, eac:maintenanceStatus, eac:publicationStatus, eac:maintenanceAgency, eac:maintenanceHistory, eac:sources"/>
            <!-- this is where things get a little messy, but i'm opting to handle this with a mode right now.
            ideally, this should be handled a bit differently, but the gist is that all of the following elements are 
            being grouped as arrays in the JSON so that we don't have to worry about duplicate keys.-->
            <xsl:apply-templates select="eac:otherRecordId[1], eac:languageDeclaration[1], eac:conventionDeclaration[1], eac:rightsDeclaration[1], eac:localTypeDeclaration[1], eac:localControl[1]" mode="json-array"/>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:*" mode="json-array">
        <xsl:variable name="current-node-name" select="local-name()"/>
        <j:array key="{$current-node-name || '_array'}">
            <xsl:apply-templates select="../eac:*[local-name() eq $current-node-name]" mode="#default"/>
        </j:array>
    </xsl:template>

    <xsl:template match="eac:recordId">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@xml:id"/>
            <!-- NOTE: for current SNAC structure, there's no way to map the xml:id value-->
            <j:string key="ark">
                <xsl:apply-templates/>
            </j:string>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:otherRecordId">
        <!-- just noting that these really could benefit from a different structure
            in EAC, especially for recording URIs -->
        <j:map>
            <xsl:apply-templates select="@*"/>
            <!-- SNAC seems to use "uri" here, but i'm using the more generic RecordId
                for now; EAC should have a way to encode URIs...
                but these otherRecordIds could be any bit of text.
            the model used by wikidata to parse out these values (URL, ID, and regex to combine) might be a good model for EAC to adopt.
            -->
            <j:string key="RecordId">
                <xsl:apply-templates/>
            </j:string>
        </j:map>
    </xsl:template>


    <!-- maps, with a key name that can be repurposed from the EAC element name
        with a "term" : value child 
        (the last bit is based on SNAC's current model)
        seems like that makes the JSON only that much harder to read/decipher, though.
        consider changing this for the generic eac2json process.
    -->
    <xsl:template match="eac:agentType | eac:eventType | eac:maintenanceStatus | eac:publicationStatus | eac:entityType">
        <j:map key="{local-name()}">
            <j:string key="term">
                <xsl:apply-templates/>
            </j:string>
            <xsl:apply-templates select="@*"/>
        </j:map>
    </xsl:template>
    
     
    <xsl:template match="eac:descriptiveNote">
        <j:map key="{local-name()}">
            <!-- this simplified form of output should be an option, as well.
            <j:string key="text">
                <xsl:value-of select="normalize-space()"/>
            </j:string>
            -->
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:p[1]" mode="json-array"/>
        </j:map>
    </xsl:template>


    <xsl:template match="eac:maintenanceAgency">
        <j:map key="{local-name()}">
            <!-- any SNAC support/mapping for agencyCode, otherAgencyCode, descriptiveNote? -->
            <xsl:apply-templates select="@xml:id, eac:agencyCode, eac:descriptiveNote"/>
            <j:array key="agencyName_array">
                <xsl:apply-templates select="eac:agencyName"/>
            </j:array>
            <xsl:if test="eac:otherAgencyCode">
                <j:array key="otherAgencyCodes">
                    <xsl:apply-templates select="eac:otherAgencyCode"/>
                </j:array>
            </xsl:if>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:maintenanceHistory">
        <j:array key="maintenanceEvents">
            <xsl:apply-templates select="eac:maintenanceEvent"/>
        </j:array>
    </xsl:template>

    <xsl:template match="eac:maintenanceEvent">
        <j:map>
            <j:string key="dataType">MaintenanceEvent</j:string>
            <xsl:apply-templates select="eac:eventType, eac:eventDateTime, eac:agentType, eac:agent"/>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:eventDateTime">
        <j:string key="{local-name()}">
            <!-- is this reasonable, or should we add both attribute and text node?-->
            <xsl:value-of select="if (@standardDateTime) then @standardDateTime else ."/>
        </j:string>
    </xsl:template>

    <xsl:template match="eac:agencyName | eac:entityId | eac:part | eac:preferredForm | eac:authorizedForm | eac:alternativeForm | eac:otherAgencyCode |
        eac:placeEntry | eac:relationEntry | eac:componentEntry">
        <j:map>
            <xsl:apply-templates select="@*"/>
            <j:string key="{local-name()}">
                <xsl:apply-templates/>
            </j:string>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:agent | eac:agencyCode | eac:event | eac:placeRole | eac:placeName | eac:abbreviation | eac:term | eac:date">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <j:string key="#text">
                <xsl:apply-templates/>
            </j:string>
        </j:map>
    </xsl:template>

    <!-- wrapper children of named arrays -->
    <xsl:template
        match="eac:languageDeclaration | eac:conventionDeclaration | eac:rightsDeclaration | eac:localTypeDeclaration | eac:localControl
        | eac:nameEntryParrallel | eac:nameEntry |
        eac:functions | eac:function | eac:generalContext |
        eac:languageUsed | eac:languagesUsed |
        eac:legalStatus | eac:legalStatuses |
        eac:localDescription | eac:localDescriptions |
        eac:mandate | eac:mandates |
        eac:occupation | eac:occupations |
        eac:place | eac:places | eac:structureOrGenealogy | eac:biogHist
        | eac:cpfRelation | eac:resourceRelation | eac:functionRelation
        | eac:setComponent
        | eac:chronList
        | eac:chronItem">
        <j:map>
            <xsl:apply-templates select="@*|* except 
                (eac:part, eac:nameEntry, eac:preferredForm, eac:authorizedForm, eac:alternativeForm, eac:function, 
                eac:languageUsed, eac:legalStatus, eac:localDescription, eac:mandate, eac:occupation, eac:place, eac:placeEntry
                , eac:citation, eac:list, eac:outline, eac:p, eac:item, eac:relationEntry, eac:componentEntry, eac:chronList, eac:chronItem)"/>
            <xsl:apply-templates select="eac:preferredForm[1], eac:authorizedForm[1], eac:alternativeForm[1], eac:nameEntry[1], eac:part[1]
                , eac:function[1], eac:languageUsed[1], eac:legalStatus[1], eac:localDescription[1]
                , eac:mandate[1], eac:occupation[1], eac:place[1], eac:placeEntry[1]
                (: the discursive set :)
                , eac:citation[1], eac:list[1], eac:outline[1], eac:p[1]
                (: and more :)
                , eac:item[1], eac:relationEntry[1], eac:componentEntry[1]
                , eac:chronList[1], eac:chronItem[1]"
                mode="json-array"/>
        </j:map>
    </xsl:template>
    
    <!-- map with an array child -->
    <xsl:template match="eac:address">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <j:array key="addressLine_array">
                <xsl:apply-templates/>
            </j:array>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:addressLine">
        <j:map>
            <xsl:apply-templates select="@*"/>
            <j:string key="#text">
                <xsl:value-of select="normalize-space()"/>
            </j:string>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:dateSet">
        <j:array key="{local-name()}">
            <xsl:if test="@*">
                <j:map>
                    <xsl:apply-templates select="@*"/>
                </j:map>     
            </xsl:if>
            <xsl:apply-templates/>
        </j:array>
    </xsl:template>
    
    <xsl:template match="eac:dateSet/eac:date | eac:dateSet/eac:dateRange">
        <j:map>
            <j:map key="{local-name()}">
                <xsl:apply-templates select="@*|*"/>
            </j:map> 
        </j:map>
    </xsl:template>

    <!-- need to note better empty elements (ditto for script, and others like these two).  not legal 
        to have an empty string element here, unless we add NULL when absent.
        what's the best way to manage this???-->
    <xsl:template match="eac:language | eac:script">
        <j:map key="{local-name()}">
            <xsl:if test="normalize-space()">
                <j:string key="#text">
                    <xsl:apply-templates/>
                </j:string>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
        </j:map>
    </xsl:template>

    <!-- array types, and keep EAC element name as JSON key name
    (still need to test for the discursive element sets in EAC)
    -->
    <xsl:template match="eac:sources">
        <j:array key="{local-name()}">
            <xsl:apply-templates/>
        </j:array>
    </xsl:template>

    <xsl:template match="eac:source">
        <j:map>
            <j:string key="dataType">Source</j:string>
            <j:map key="type">
                <xsl:apply-templates select="@xlink:type"/>
                <j:string key="type">source_type</j:string>
            </j:map>
            <!-- change to process all?..  probably need to skip BinWrap? -->
            <xsl:apply-templates select="* except eac:objectBinWrap"/>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:sourceEntry">
        <!-- SNAC mapping, hence why it's separte for now.  not sure that this should really be in the mapping, though-->
        <j:string key="displayName">
            <xsl:apply-templates/>
        </j:string>
    </xsl:template>

    <!-- keeping things round-trippable, i'm going to turn this into a map despite that SNAC doesn't currently map to this element -->
    <xsl:template match="eac:cpfDescription">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*|*"/>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:multipleIdentities/eac:cpfDescription">
        <j:map>
            <xsl:apply-templates select="@*|*"/>
        </j:map>
    </xsl:template>

    <xsl:template match="eac:identity">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:entityType, eac:descriptiveNote"/>
            <xsl:apply-templates select="eac:entityId[1], eac:nameEntryParallel[1], eac:nameEntry[1]" mode="json-array"/>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:description">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:existDates"/>
            <xsl:apply-templates select="eac:function[1], eac:functions[1]
                , eac:generalContext[1]
                , eac:languageUsed[1], eac:languagesUsed[1]
                , eac:legalStatus[1], eac:legalStatuses[1]
                , eac:localDescription[1], eac:localDescriptions[1]
                , eac:mandate[1], eac:mandates[1]
                , eac:occupation[1], eac:occupations[1]
                , eac:place[1], eac:places[1]
                , eac:structureOrGenealogy[1]
                , eac:biogHist[1]" 
                mode="json-array"/>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:relations">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:cpfRelation[1], eac:resourceRelation[1], eac:functionRelation[1]" mode="json-array"/>
        </j:map>
    </xsl:template>
    
    <xsl:template match="eac:alternativeSet">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="eac:setComponent[1]" mode="json-array"/>
        </j:map>
    </xsl:template>


    <xsl:template match="eac:objectXMLWrap">
        <!-- any other parameters needed?
            And is SNAC okay with having the EAC namespaces on the objectXMLWrap element, which is correct, or would it prefer to have  those removed?-->
        <j:string key="#xml">
            <xsl:sequence select="serialize(., map{'json-node-output-method':'xml'})"/>
        </j:string>
    </xsl:template>
    
    <!-- since abstract, citation, item, and p can have mixed content (e.g. span)
    these 4 elements will be treated a bit differently.
    we could try to preserve the mixed content with span in JSON by naming the text
    nodes, but i think it's probably best to output those elements as unknown text strings that can
    contain XML.
    still need to update to include attributes.
    -->
    <xsl:template match="eac:abstract">
        <xsl:choose>
            <xsl:when test="eac:span">
                <j:string key="{local-name()}">
                    <xsl:sequence select="serialize(., map{'json-node-output-method':'xml'})"/>
                </j:string>
            </xsl:when>
            <xsl:otherwise>
                <j:string key="{local-name()}">
                    <xsl:value-of select="normalize-space()"/>
                </j:string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="eac:citation|eac:item|eac:p">
        <xsl:choose>
            <xsl:when test="eac:span">
                <j:string>
                    <xsl:sequence select="serialize(., map{'json-node-output-method':'xml'})"/>
                </j:string>
            </xsl:when>
            <xsl:otherwise>
                <j:string>
                    <xsl:value-of select="normalize-space()"/>
                </j:string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- named maps -->
    <xsl:template match="eac:dateRange | eac:fromDate | eac:toDate">
        <j:map key="{local-name()}">
            <xsl:apply-templates select="@*|*"/>
        </j:map>
    </xsl:template>
    
    <!-- different whether in nameEntryParallel or not.
    could combine these with the above, but keeping them separate until we can write some 
    tests for these transformations to make these differences more clear. -->
    <xsl:template match="eac:nameEntry/eac:useDates">
        <j:map key="{local-name()}">
            <xsl:apply-templates/>
        </j:map>
        <xsl:apply-templates select="@*"/>
    </xsl:template>
    <xsl:template match="eac:nameEntryParallel/eac:useDates">
        <j:map>
            <j:map key="{local-name()}">
                <xsl:apply-templates/>
            </j:map>
            <xsl:apply-templates select="@*"/>
        </j:map>
    </xsl:template>
    
    <!-- ATTRIBUTES -->

    <!-- SNAC uses "type" here. -->
    <xsl:template match="@localType">
        <j:string key="@localType">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <!-- SNAC uses "term" here. -->
    <xsl:template match="@xlink:type">
        <j:string key="@type">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <xsl:template match="@xml:lang">
        <j:string key="@lang">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <xsl:template match="@xml:id">
        <j:string key="@id">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <xsl:template match="@xml:base">
        <j:string key="@xml_base_uri">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <xsl:template match="@*">
        <j:string key="{'@' || local-name()}">
            <xsl:value-of select="."/>
        </j:string>
    </xsl:template>

    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>

</xsl:stylesheet>
