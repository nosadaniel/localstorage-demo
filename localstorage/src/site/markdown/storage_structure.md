Local Storage Usage
===================
The local storage offers the data exchange platform for the GEIGER toolbox. 

The storage is focussed on the following strengths:
- allow data synchronization in a GDPR compliant way among multiple devices and users.
- allow efficient, event driven updates on the data

In general, it offers a tree-like storage where there is one root entry and starting from there one or multiple sub-entries called nodes.     

A [Node]{xref/ch/fhnw/geiger/localstorage/db/data/Node.html} represents node within the tree shaped graph. Any of this data consists out of the following information:
- Name of the node (mandatory)
- reference to the predecessor node (mandatory)
- ordinals
    - owner
    - visibility
- key/value pairs
    - key
    - value
    - type (required for searching values of a specific type)
    - description (shown to get GDPR consent) 