perl -pi -e 's/\<li\>\<a href=\"buildOTU.html\">Build OTUs and assign taxonomy\<\/a\>\<\/li\>/\<li\>\<a href=\"buildOTU.html\">Build OTUs and assign taxonomy\<\/a\>\<\/li\>\'$'\n<li\>\<a href=\"integration.html\">Integrate DADA2, TAG.ME and Phyloseq\<\/a\>\<\/li\>/g' *.html