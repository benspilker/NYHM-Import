
ztaccount=$(curl -sH 'Accept: application/json' -H 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq' https://my.zerotier.com/api/network)

ztidvar=$(echo $ztaccount | '/usr/bin/jq' '.[].config.id' | sed 's/"//g')
ztidarr=($ztidvar)

tiervar=$(echo $ztid | '/usr/bin/jq' '.[].config.ipAssignmentPools' | sed 's/"ipRangeStart": "172.22.172.1".//g' | sed 's/"ipRangeEnd": "172.22.172.//g' | sed 's/{//g' | sed 's/}//g' | sed 's/"//g' | sed 's/[][]//g' | sed 's/ //g')
tierarr=($tiervar)

totalmembervar=$(echo $ztid | '/usr/bin/jq' '.[].totalMemberCount')
totalmemberarr=($totalmembervar)

onlinemembervar=$(echo $ztid | '/usr/bin/jq' '.[].onlineMemberCount')
onlinememberarr=($onlinemembervar)

notonline=$(for ((i=0; i<${#onlinememberarr[*]}; i++));  do   if (("${onlinememberarr[i]}" < "2" )); then echo "$i"; fi; done)
notonlinearr=($notonline)

varlist3=$(for ((i=0; i<${#tierarr[*]}; i++));  do   if [ ${tierarr[i]} == '3' ]; then echo "$i"; fi; done)
varlistarr3=($varlist3)

resetlist5=$(for ((i=0; i<${#totalmemberarr[*]}; i++));  do   if (("${totalmemberarr[i]}" >= "5" )); then echo "$i"; fi; done)
resetlistarr5=($resetlist5)

resetlist2=$(for ((i=0; i<${#totalmemberarr[*]}; i++));  do   if (("${totalmemberarr[i]}" >= "2" )); then echo "$i"; fi; done)
resetlistarr2=($resetlist2)

over5reset=$(printf "%s\n" ${resetlistarr5[@]} ${notonlinearr[@]} | sort | uniq -d)
over5resetarr=($over5reset)

networkstoreset5=$(for ((i=0; i<${#over5resetarr[*]}; i++));  do printf "%s\n" ${ztidarr[${over5resetarr[i]}]}; done)

level3reset=$(printf "%s\n" ${varlistarr3[@]} ${resetlistarr2[@]} | sort | uniq -d)
level3resetarr=($level3reset)

level3resetnotonline=$(printf "%s\n" ${level3resetarr[@]} ${notonlinearr[@]} | sort | uniq -d)
level3resetnotonlinearr=($level3resetnotonline)

networkstoreset3=$(for ((i=0; i<${#level3resetnotonlinearr[*]}; i++));  do printf "%s\n" ${ztidarr[${level3resetnotonlinearr[i]}]}; done)

allnetworkstoreset=($networkstoreset3 $networkstoreset5)

printf "%s\n" ${allnetworkstoreset[@]}
