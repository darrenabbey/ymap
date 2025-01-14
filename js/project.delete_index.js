function deleteProjectConfirmation(project,key){
	console.log("$ project = '"+project+"'");
	console.log("$ key     = '"+key+"'");
	panel_iframe             = document.getElementById('panel_manageDataset_iframe');
	dom_object               = panel_iframe.contentDocument.getElementById('p_delete_'+key);

	dom_object.innerHTML     = "<b><font color=\"red\">[Are you sure?]</font><button type='button' onclick='parent.deleteProject_yes(\""+project+"\",\""+key+"\")'>Yes, delete.</button>";
	dom_object.innerHTML    += "<button type='button' onclick='parent.deleteProject_no(\""+project+"\",\""+key+"\")'>No, cancel</button></b>";

	dom_button               = panel_iframe.contentDocument.getElementById('project_delete_'+key);
	dom_button.style.display = 'none';
}

function deleteProject_yes(project,key){
	console.log('deleteProject_yes');
	$.ajax({
		url : 'project.delete_server.php',
		type : 'post',
		data : {
			project: project
		},
		success : function(answer){
			console.log('deleteProject_yes return: '+answer);
			if(answer == "COMPLETE"){
				// reload entire page - in order to ensure the update of the quota calculation
				window.top.location.reload();
			}
		}
	});

	// Hide delete confirmation user interface.
	dom_object           = panel_iframe.contentDocument.getElementById('p_delete_'+key)
	dom_object.innerHTML = "";
	dom_button               = panel_iframe.contentDocument.getElementById('project_delete_'+key);
	dom_button.style.display = 'inline';

	// Update user interface display panel to remove deleted project.
	update_projectsShown_after_project_delete(key);
}

function deleteProject_no(project,key){
	console.log('deleteProject_no');
	panel_iframe         = document.getElementById('panel_manageDataset_iframe');

	// Hide delete confirmation user interface.
	dom_object           = panel_iframe.contentDocument.getElementById('p_delete_'+key)
	dom_object.innerHTML = "";
	dom_button               = panel_iframe.contentDocument.getElementById('project_delete_'+key);
	dom_button.style.display = 'inline';
}

