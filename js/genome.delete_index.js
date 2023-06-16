function deleteGenomeConfirmation(genome,key){
	console.log("$ genome    = '"+genome+"'");
	console.log("$ key       = '"+key+"'");
	panel_iframe             = document.getElementById('panel_genome_iframe');
	dom_object               = panel_iframe.contentDocument.getElementById('g_delete_'+key);

	dom_object.innerHTML     = "<b><font color=\"red\">[Are you sure?]</font><button type='button' onclick='parent.deleteGenome_yes(\""+genome+"\",\""+key+"\")'>Yes, delete.</button>";
	dom_object.innerHTML    += "<button type='button' onclick='parent.deleteGenome_no(\""+genome+"\",\""+key+"\")'>No, cancel</button></b>";

	// turn delete button off for this genome.
	dom_button               = panel_iframe.contentDocument.getElementById('genome_delete_'+key);
	dom_button.style.display = 'none';

	// turn finalize button off for this genome.
	dom_button2               = panel_iframe.contentDocument.getElementById('genome_finalize_'+key);
	dom_button2.style.display = 'none';
}

function deleteGenome_yes(genome,key){
	$.ajax({
		url : 'genome.delete_server.php',
		type : 'post',
		data : {
			genome: genome
		},
		success : function(answer){
			if(answer == "COMPLETE"){
				// reload entire page - in order to ensure the update of the quota calculation
				window.top.location.reload();
			}
		}
	});
}


function deleteGenome_no(genome,key){
	panel_iframe             = document.getElementById('panel_genome_iframe');
	dom_object               = panel_iframe.contentDocument.getElementById('g_delete_'+key)
	dom_object.innerHTML     = "";

	// turn delete button back on for this genome.
	dom_button               = panel_iframe.contentDocument.getElementById('genome_delete_'+key);
	dom_button.style.display = 'inline';

	// turn finalize button back on for this genome.
	dom_button2               = panel_iframe.contentDocument.getElementById('genome_finalize_'+key);
	dom_button2.style.display = 'inline';
}
