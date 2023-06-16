function minimizeProjectConfirmation(project,key){
	console.log("$ project = '"+project+"'");
	console.log("$ key     = '"+key+"'");
	panel_iframe             = document.getElementById('panel_manageDataset_iframe');
	dom_object               = panel_iframe.contentDocument.getElementById('p_minimize_'+key);

	dom_object.innerHTML     = "<b><font color=\"red\">[Minimized projects can't be used for further analysis. Are you sure?]</font><button type='button' onclick='parent.minimizeProject_yes(\""+project+"\",\""+key+"\")'>Yes, minimize.</button>";
	dom_object.innerHTML    += "<button type='button' onclick='parent.minimizeProject_no(\""+project+"\",\""+key+"\")'>No, cancel</button></b>";

	dom_button               = panel_iframe.contentDocument.getElementById('project_minimize_'+key);
	dom_button.style.display = 'none';
}

function minimizeProject_yes(project,key){
	console.log('minimizeProject_yes');
	$.ajax({
		url : 'project.minimize_server.php',
		type : 'post',
		data : {
			project: project
		},
		success : function(answer){
			console.log('minimizeProject_yes return: '+answer);
			if(answer == "COMPLETE"){
				// reload entire page - in order to ensure the update of the quota calculation
				window.top.location.reload();
			}
		}
	});

	// Reload user interface to recalculate project sizes.
	window.top.location.reload();
}

function minimizeProject_no(project,key){
	console.log('minimizeProject_no');
	panel_iframe         = document.getElementById('panel_manageDataset_iframe');
	dom_object           = panel_iframe.contentDocument.getElementById('p_minimize_'+key)
	dom_object.innerHTML = "";

	dom_button               = panel_iframe.contentDocument.getElementById('project_minimize_'+key);
	dom_button.style.display = 'inline';
}

