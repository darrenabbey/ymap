<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
	<!--
	 .tab { margin-left: 40px; }
	-->
</style>
<font size='3'><b>Primary citations related to YMAP.</b></font><br>
<font size="2">
<p>
	Abbey DA, Funt J, Lurie-Weinberger MN, Thompson DA, Regev A, Myers CL, Berman J. 2014.<br>
	YMAP: a pipeline for visualization of copy number variation and loss of heterozygosity in<br>
	eukaryotic pathogens. Genome Med. 2014; 6(11):100.
	<a href="https://pubmed.ncbi.nlm.nih.gov/25505934/" target="_blank">https://pubmed.ncbi.nlm.nih.gov/25505934/</a><br>
	<p class="tab">
	This paper introduced YMAP and described it in some detail as it was in 2014.<br>
	This paper introduced a full-resolution haplotype map (hapmap) for <i>Candida albicans</i> strains derived from SC5314, built using YMAP, & derived from the array based hapmap of Abbey <i>et al</i> 2011.<br>

	YMAP has seen major improvements in security and administrative functions since 2014, though these changes are for the most part invisible to a YMAP user.
	</p>
</p>
<p>
	Abbey D, Hickman M, Gresham D, Berman J. High-resolution SNP/CGH microarrays reveal<br>
	the accumulation of loss of heterozygosity in commonly used Candida albicans strains<br>
	G3 (Bethesda). 2011; 1(7):523–530.
	<a href="https://pubmed.ncbi.nlm.nih.gov/22384363/" target="_blank">https://pubmed.ncbi.nlm.nih.gov/22384363/</a><br>
	<p class="tab">
	This paper described the construction of a hapmap for <i>C. albicans</i> strains derived from SC5314, using custom designed microarrays.<br>
	</p>
</p>
</font>

<font size='3'><b>Papers which have cited YMAP.</b></font><br>
<font size="2">
<p>
	At one time I was collecting a list of specific papers that cited YMAP, but for ease of capturing<br>
	new citations I will refer you to
	<a href="https://pubmed.ncbi.nlm.nih.gov/?linkname=pubmed_pubmed_citedin&from_uid=25505934" target="_blank">PubMed</a> and 
	<a href="https://scholar.google.com/scholar?cites=15360153506490453844&as_sdt=5,24&sciodt=0,24&hl=en" target="_blank">Google Scholar</a>
</p>
</font>
