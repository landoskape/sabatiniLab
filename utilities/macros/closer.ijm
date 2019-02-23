list = getList("window.titles"); 
     for (i=0; i<list.length; i++){ 
     winame = list[i]; 
     	selectWindow(winame); 
     run("Close"); 
     } 

       macro "Close All Windows" { 
      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
  } 