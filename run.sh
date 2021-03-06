#!/bin/bash -x

env -
source /.env

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

X_SG_ID=($SG_ID)
X_WHITELIST=($WHITELIST)

for SG in $SG_ID; do
  aws ec2 revoke-security-group-egress --group-id $SG --ip-permissions "$(aws ec2 describe-security-groups --group-ids $SG | jq '.SecurityGroups[].IpPermissionsEgress')"
done

declare -i COUNT=0
declare -i MULTIPLIER=0
for I in `seq 0 $(expr ${#X_WHITELIST[@]} - 1)`; do
  if [[ $COUNT -lt 25 ]]; then
    echo $I - ${X_WHITELIST[$I]} - ${X_SG_ID[$MULTIPLIER]}
    if [[ ${X_WHITELIST[$I]} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
      aws ec2 authorize-security-group-egress --group-id ${X_SG_ID[$MULTIPLIER]} --ip-permissions '{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "'${X_WHITELIST[$I]}'"}]}'
      aws ec2 authorize-security-group-egress --group-id ${X_SG_ID[$MULTIPLIER]} --ip-permissions '{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "'${X_WHITELIST[$I]}'"}]}'
    else
      aws ec2 authorize-security-group-egress --group-id ${X_SG_ID[$MULTIPLIER]} --ip-permissions '{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "'${X_WHITELIST[$I]}'/32"}]}'
      aws ec2 authorize-security-group-egress --group-id ${X_SG_ID[$MULTIPLIER]} --ip-permissions '{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "'${X_WHITELIST[$I]}'/32"}]}'
    fi
    COUNT+=1
  else
    echo "Warning: Security Group ${X_SG_ID[$MULTIPLIER]} reach maximum 50 egress rules."
    MULTIPLIER+=1
    COUNT=0
  fi
done
