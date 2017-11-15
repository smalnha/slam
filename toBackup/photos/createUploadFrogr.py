import json
from os import listdir
from os.path import isfile, join
import os
import pathlib
import re
import sys

mypath = "."
onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]
#print ("files: ", onlyfiles)

def splitall(path):
    allparts = []
    while 1:
        parts = os.path.split(path)
        if parts[0] == path:  # sentinel for absolute paths
            allparts.insert(0, parts[0])
            break
        elif parts[1] == path: # sentinel for relative paths
            allparts.insert(0, parts[1])
            break
        else:
            path = parts[0]
            allparts.insert(0, parts[1])
    return allparts

photoDir=sys.argv[1].rstrip('/') #"1996/1996-09-27-AndrewBirth"
photoDirPath=os.path.join(os.getcwd(), photoDir)
albumTitle=os.path.basename(photoDirPath)

outputfile=sys.argv[2] if len(sys.argv)>2 else 'upload.frogr'

# exit if not exist
pathlib.Path(photoDirPath).resolve()
print(photoDirPath, "title="+albumTitle)

# add year tag
splitPath=splitall(photoDir)
yearStr=splitPath[0]
tagstr=[ yearStr ]

if len(splitPath)==1:
   albumTitle=yearStr+"-various"
else:
   albumTitle="/".join(splitPath[1:])

try:
   with open(photoDirPath+"/tags.txt") as f:
      content = f.readlines()
   # you may also want to remove whitespace characters like `\n` at the end of each line
   content = [x.strip() for x in content] 
   tagstr.extend(content)
except FileNotFoundError:
   print ("Tags file not present:", photoDirPath+"/tags.txt")

try:
   tagstr.remove("")
except ValueError:
   print ("")

tagMap=[
      [r'(?:bday|birthday)$',"birthday"],
      [r'birth',"birthday"],
      [r'frances',"Frances"],
      [r'hao',"Hao"],
      [r'frances',"Frances"],
      [r'yvonne',"Yvonne"],
      [r'frank',"Frank"],
      [r'andrew',"Andrew"],
      [r'dung',"Dung"],
      [r'andrea',"Andrea"],
      [r'elena',"Elena"],
      ]
def addMoreTags(photoDirPath, filename):
   tagstr=[]
   for [regexpStr, tag] in tagMap:
      if re.search(regexpStr, photoDirPath+"/"+filename, re.IGNORECASE):
         tagstr.append(tag)
   return tagstr

jpgfiles = [filename for filename in os.listdir(photoDirPath) 
   if re.search(r'\.(?:jpg|png|mpg|avi|mov)$', filename, re.IGNORECASE)]

jpgfiles.sort()
#print ("jpgfiles: ", jpgfiles)

actualPath="/mnt/share/archive/photos/"+photoDir+"/"
#for jpgfile in jpgfiles:
#   print ("f= ", pathlib.Path(actualPath+jpgfile).as_uri())

photoRecs=[]
for jpgfile in jpgfiles: 
   photoRec={
      'fileuri': pathlib.Path(actualPath+jpgfile).as_uri(),
      'title': os.path.splitext(jpgfile)[0],
      'tags-string': ' '.join(sorted(list(set(tagstr + addMoreTags(photoDirPath, jpgfile))))),
      "is-family": True,
      "photosets": [ "123" ]
   }
   photoRecs.append(photoRec)
#print ("photoRecs: ", photoRecs)

data = {
   "data":{
      "photosets":[
         {
            "title":albumTitle,
            "description":photoDirPath,
            "local-id":"123"
         }
      ],
      "pictures": photoRecs
   }
}

json_str = json.dumps(data)

with open(outputfile, 'w') as outfile:
    json.dump(data, outfile, indent=4)
