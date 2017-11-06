<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:alto="http://schema.ccs-gmbh.com/docworks/version20/alto-1-4.xsd" xmlns:str="http://exslt.org/strings" xmlns:mets="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" extension-element-prefixes="str">

	<!-- XSL parameters -->
	<xsl:param name="xslParam" select="otherwise" />

	<!-- global variables  -->
    <xsl:variable name="PATH">..\DOCS\</xsl:variable>



	<xsl:output method="xml" omit-xml-declaration="no"/>
	<xsl:template match="/">
		<analyseAlto>
			<metad>

				<!-- bibliographic metadata
count(//mets:file[substring(@ID, 4)='ALTO'])-->
				<title>
					<xsl:value-of select="//mods:titleInfo/mods:title"/>
				</title>
				<genre>PERIODICAL</genre>

				<dateEdition>
					<xsl:value-of select="//mods:dateIssued"/>
				</dateEdition>
				<xsl:variable name="nbPages">
					<xsl:value-of select="count(//mets:file[substring(@ID,0,5)='ALTO'])"/>
				</xsl:variable>
				<nbpages>
					<xsl:value-of select="$nbPages"/>
				</nbpages>

			</metad>
			<ocr>
				<!-- no quality rate  -->
			</ocr>
			<!-- UC number = the file where to look for the ALTO -->
			<!-- analysis of METS content  -->
			<contents>
			     <nbArticle>
					<xsl:value-of select="count(/mets:mets/mets:structMap[@TYPE='LOGICAL']//mets:div[@TYPE='ARTICLE'])"/>
				</nbArticle>
				<!--
				<blocTab>
					<xsl:value-of select="count(/mets:mets/mets:structMap[@TYPE='LOGICAL']//mets:div[@TYPE='TABLE'])"/>
				</blocTab>
				<blocPub>
					<xsl:value-of select="count(/mets:mets/mets:structMap[@TYPE='LOGICAL']//mets:div[@TYPE='ADVERTISEMENT'])"/>
				</blocPub>
				<blocIllustration>
					<xsl:value-of select="count(/mets:mets/mets:structMap[@TYPE='LOGICAL']//mets:div[@TYPE='ILLUSTRATION'])"/>
				</blocIllustration>
				-->
			   <!-- <xsl:for-each select="//mets:file[substring(@ID,0,5)='ALTO']">

					<xsl:variable name="tmp">
						<xsl:value-of select="@ID"/>
					</xsl:variable>

					<xsl:variable name="numPage">
					   <xsl:value-of select="number($nomFic)"/>
					</xsl:variable>
					<xsl:value-of select="$numPage"/>
					</xsl:for-each>-->

					<!-- analysis of ALTO content  -->
					<xsl:for-each select="/mets:mets/mets:fileSec/mets:fileGrp/mets:fileGrp/mets:file[substring(@ID,0,5)='ALTO']/*">
					<page>
					    <xsl:variable name="tmp" select="@xlink:href"/>
					    <xsl:variable name="ficAlto">
						     <xsl:value-of select="substring($tmp,10)"/> <!-- suppress "file://."  -->
					    </xsl:variable>
						<fichier>
						     <xsl:value-of select="$ficAlto"/>
						</fichier>

						<!-- calculating the file path  -->

					<!-- document folders are stored in the DOCS folder, at the same level as XSL  -->
					<xsl:variable name="path" select="concat($PATH,$xslParam)"/>
					<xsl:variable name="path" select="concat($path,'\')"/>
					<xsl:variable name="path" select="concat($path,$ficAlto)"/>

					<xsl:choose>
							<xsl:when test="document($path)">
								<nbString>
								    <xsl:value-of select="count(document($path)/alto/Layout/Page/PrintSpace//String)"/>
								</nbString>
							</xsl:when>
							<xsl:otherwise>
								<FICHIER_ABSENT/>
							</xsl:otherwise>
						</xsl:choose>

						<nbCar><!-- useless
									<xsl:variable name="numCar">
										<xsl:for-each select="document($path)//String">
											<xsl:value-of select="@CONTENT"/>
										</xsl:for-each>
									</xsl:variable>
									<xsl:value-of select="string-length($numCar)"/>-->
						</nbCar>
						<!-- the blocks   -->
						<blocTexte>
								<xsl:value-of select="count(document($path)/alto/Layout/Page/PrintSpace//TextBlock)"/>
						</blocTexte>
						<blocTab>
								<xsl:value-of select="count(document($path)/alto/Layout/Page/PrintSpace//ComposedBlock[(@TYPE='Table')])"/>
						</blocTab>
						<!-- advertisements   -->
						<blocPub>
								<xsl:value-of select="count(document($path)/alto/Layout/Page/PrintSpace//ComposedBlock[(@TYPE='Advertisement')])"/>
						</blocPub>
						<!-- advertisements text blocks  : useless because a TextBlock per ComposedBlock
						<blocTextePub>
								<xsl:value-of select="count(document($path)//ComposedBlock[(@TYPE='Advertisement')]/TextBlock)"/>
						</blocTextePub> -->
						<!-- images  -->
						<blocIllustration>
								<xsl:value-of select="count(document($path)/alto/Layout/Page/PrintSpace//Illustration)+count(document($path)/alto/Layout/Page/PrintSpace//ComposedBlock[(@TYPE='Illustration')])"/>
						</blocIllustration>
						<!-- advertisements image blocks : useless because not segmented
						<blocIllustrationPub>
								<xsl:value-of select="count(document($path)//ComposedBlock[(@TYPE='Advertisement')]/Illustration)"/>
						</blocIllustrationPub> -->
						<sommeWC>
							<xsl:value-of select="sum(document($path)/alto/Layout/Page/PrintSpace//String/@WC)"/>
						</sommeWC>
					</page>
				</xsl:for-each>
			</contents>
		</analyseAlto>
	</xsl:template>
</xsl:stylesheet>
