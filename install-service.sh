#!/bin/bash
#Check if the release exists at all.
function list_include_item (){
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}

releaseName="example"
releaseList=`helm list -q | tr '\\n' ' '`
echo $releaseList
if `list_include_item "$releaseList" "$releaseName"`; then
  releaseStatus=`helm status ${releaseName} -o json | jq '.info.status.code'`
  echo "release status $releaseStatus"
  if [ $releaseStatus != "1" ]; then
    #The release is in FAILED state. Attempt to rollback.
	releaseRevision=`helm history ${releaseName} | tail -1 | awk '{ print \$1}'`
	echo "releaseRevision $releaseRevision"
	if [ $releaseRevision == "1" ]; then
		purge=`helm del --purge ${releaseName}`
	else
		releaseRevision=`helm history ${releaseName} | tail -2 | head -1 | awk '{ print \$1}'`
		rollback=`helm rollback ${releaseName} ${releaseRevision}`
	fi
  fi
else 
  echo "The release does not exist, install it."
fi

#Upgrade or freshly install a micro-service release.
installrelease=`helm upgrade ${releaseName} ./firstchart --install --set service.type=LoadBalancer --force --wait --timeout 500`

#Verify whether the deployment passed or not.
helmStatus=`helm status ${releaseName} -o json | jq '.info.status.code'`
echo "helm status $helmStatus"
releaseRevision=`helm history ${releaseName} | tail -2 | head -1 | awk '{ print \$1}'`
if [ $helmStatus != "1" ]; then
	echo "build failed"
	printf '[{"release":"%s","revision":"%s","status":"%s"}]' "$releaseName" "$releaseRevision" "failed" > build.json
	exit 1
else
	echo "build succeeded"
	printf '[{"release":"%s","revision":"%s","status":"%s"}]' "$releaseName" "$releaseRevision" "succeeded" > build.json
	exit 0
fi

