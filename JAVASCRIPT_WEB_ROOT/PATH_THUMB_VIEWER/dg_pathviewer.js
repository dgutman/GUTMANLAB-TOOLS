function init(){	dhtmlx.image_path='./codebase/imgs/';

	var main_layout = new dhtmlXLayoutObject(document.body, '3T');

	var a = main_layout.cells('a');
	a.setHeight('150');
	a.fixSize(0,1);






}
var stored_data =  '[{"element":"fake","id":"gui","_text":"Main UI","freeze":true,"open":true,"$parent":0,"$level":1,"$count":1,"events":{}},{"element":"windows","id":"windows","name":"windows","_text":"Popups","freeze":"partially","$parent":0,"$level":1,"$count":0,"events":{}},{"element":"main_layout","open":true,"id":"top","name":"main_layout","_text":"Layout : <span class=\'dhx_element_name\'>main_layout</span>","events":{},"freeze":"partially","image_path":"./codebase/imgs/","scheme":"3T","$parent":"gui","$level":2,"$count":3,"$selected":false,"effect":0},{"element":"cell","id":"1","cell_name":"a","name":"a","events":{},"_text":"Cell : <span class=\'dhx_element_name\'>a</span>","$parent":"top","$level":3,"$count":0,"$selected":true,"fixed_height":1,"height":"150","open":true,"toolbar":0},{"element":"cell","id":"2","cell_name":"b","name":"b","events":{},"_text":"Cell : <span class=\'dhx_element_name\'>b</span>","$parent":"top","$level":3,"$count":0},{"element":"cell","id":"3","cell_name":"c","name":"c","events":{},"_text":"Cell : <span class=\'dhx_element_name\'>c</span>","$parent":"top","$level":3,"$count":0}]';