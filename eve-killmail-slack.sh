SLACK_TOKEN=""

function killmails {
#download previous day kills and save formatted json
curl -s https://zkillboard.com/api/corporationID/$1/pastSeconds/86400/ | jq '.' > $1.json
x=0
#for each killmail
for k in `jq -r '.[]|.killID' $1.json`; do
        #check if new km
        if [[ ! $(grep -Fx $k killmails.dat) ]]; then
                #get variables for output
                killID=$(jq -r ".[$x] | .killID" $1.json)
                solarSystemID=$(jq -r ".[$x] | .solarSystemID" $1.json)
#		killTime=$(jq -r ".[$x] | .killTime" $1.json)
#		killTimef=$(date -d"$killTime" "+%T")
                victim_shipTypeID=$(jq -r ".[$x] | .victim.shipTypeID" $1.json)
                victim_corporationID=$(jq -r ".[$x] | .victim.corporationID" $1.json)
                victim_characterName=$(jq -r ".[$x] | .victim.characterName" $1.json)
                victim_corporationName=$(jq -r ".[$x] | .victim.corporationName" $1.json)

                #find finalBlow and set as attacker
                fb=0
                for a in `jq -r ".[$x].attackers[].finalBlow" $1.json`; do
                        if [ $a -eq 1 ]; then
                                attackers_characterName=$(jq -r ".[$x].attackers[$fb].characterName" $1.json)
                                attackers_corporationName=$(jq -r ".[$x].attackers[$fb].corporationName" $1.json)
                        else
                                ((fb++))
                                continue
                        fi
                done
                attackers_count=$(jq -r ".[$x].attackers[].finalBlow" $1.json | wc -l)
                zkb_value=$(jq -r ".[$x] | .zkb.totalValue" $1.json)
                zkb_valuef=$(printf "%'.f isk" $zkb_value)
		zkbURL=$(curl -s https://www.googleapis.com/urlshortener/v1/url -H 'Content-Type: application/json' -d "{\"longUrl\": \"https://zkillboard.com/kill/$killID/\"}" | jq -r '.id')

		#get shipName from shipID
		shipName=$(grep "$victim_shipTypeID," ships.id | cut -f2 -d',' | xargs)
		if [[ ! $shipName ]]; then
			shipName="$(curl -s https://public-crest.eveonline.com/types/$victim_shipTypeID/ | jq '.name' | xargs)"
			echo $victim_shipTypeID,$shipName >> ships.id
		fi
		#get systemName from solarSystemID
		systemName=$(grep "$solarSystemID," systems.id | cut -f2 -d',' | xargs)
                if [[ ! $solarSystemID ]]; then
                        systemName="UNKNOWN"
                fi


		#build message
		RED="\033[31m"
		ORANGE="\033[33m"
		GREEN="\033[32m"
		BLUE="\033[34m"
		PURPLE="\033[35m"
		WHITE="\033[37m"
		BOLD=$(tput bold)
		RESET=$(tput sgr0)

		if (( ${zkb_value%.*} < 500000000 )); then
			#DIM
			ACCENT="\e[2m"
		elif (( ${zkb_value%.*} <= 1500000000 )); then
			#NORMAL/BOLD
			ACCENT="\e[1m"
			SACCENT=" "
		elif (( ${zkb_value%.*} <= 3000000000 )); then
                        ACCENT="\e[7m"
                        SACCENT=" "
                elif (( ${zkb_value%.*} <= 10000000000 )); then
                        ACCENT="\e[7m"
                        SACCENT=":siren:"
		else
			#INVERTED
			ACCENT="\e[7m"
			SACCENT=":hypnotoad:"
		fi

		if [ -z "$attackers_corporationName" ]; then
			attackers_corporationName="NPC"
		fi
		if [ -z "$zkbURL" ]; then
			zkbURL="https://zkillboard.com/kill/$killID/"
		fi

		vmessage="$ACCENT($attackers_count) $RED[$attackers_corporationName]$RESET$ACCENT $attackers_characterName$RESET$ACCENT killed $RED$ACCENT[$victim_corporationName]$RESET$ACCENT $victim_characterName$RESET$ACCENT in a $shipName in $systemName ($zkb_valuef)  $ORANGE$zkbURL$RESET"
		amessage="$ACCENT($attackers_count) $GREEN[$attackers_corporationName]$RESET$ACCENT $attackers_characterName$RESET$ACCENT killed $GREEN$ACCENT[$victim_corporationName]$RESET$ACCENT $victim_characterName$RESET$ACCENT in a $shipName in $systemName ($zkb_valuef)  $ORANGE$zkbURL$RESET"

                pvsmessage="$SACCENT:heart: *$attackers_corporationName* killed *$victim_corporationName* $victim_characterName _in *$shipName* @ $systemName ($zkb_valuef)_   $zkbURL"
                pasmessage="$SACCENT:green_heart: *$attackers_corporationName* killed *$victim_corporationName* $victim_characterName _in *$shipName* @ $systemName ($zkb_valuef)_   $zkbURL"

		vsmessage=$(echo $pvsmessage | sed "s/'//g")
		asmessage=$(echo $pasmessage | sed "s/'//g")

		if (( ${zkb_value:0:${#zkb_value}-3} > 50000000 )); then
                if [ $victim_corporationID == $1 ]; then
			#console output
			printf "%s$vmessage"
			echo

			if (( ${zkb_value%.*} > 500000000 )); then
				#slack output
        	                slack=$(printf "curl -s -X POST --data-urlencode \'payload={\"channel\": \"#killbotspam\", \"username\": \"kill\", \"icon_emoji\": \":eve:\", \"mrkdwn\": \"true\", \"text\": \"$vsmessage\"}\' $SLACK_TOKEN > /dev/null")
                	        eval $slack
			fi
                else
			#consolde output
			printf "%s$amessage"
			echo
                        if (( ${zkb_value%.*} > 500000000 )); then
				#slack output
        	                slack=$(printf "curl -s -X POST --data-urlencode \'payload={\"channel\": \"#killbotspam\", \"username\": \"kill\", \"icon_emoji\": \":eve:\", \"mrkdwn\": \"true\", \"text\": \"$asmessage\"}\' $SLACK_TOKEN> /dev/null")
				eval $slack
			fi
                fi
		fi
        echo $k >> killmails.dat
        fi
#	newfile=$(tail -n1000 killmails.dat)
#	echo $newfile > killmails.dat
 ((x++))
done
}


while true
do
    killmails 98323701	#novac
    killmails 98290394	#lazerhawks
    killmails 98380820	#exit strategy
    killmails 98297019	#iso5
    killmails 1705300610	#tdsin
    killmails 98360068	#suddenly carebears
    killmails 164893220	#repo industries

    killmails 98040755	#hard knocks
	killmails 98427377	#404 hole not found
	killmails 389326446	#verge of collapse
	killmails 98252033	#holecontrol
	killmails 1162329807	#ixtab
	killmails 741627015	#odins call
	killmails 98353041	#dura lexx

	killmails 98224068 	#dropbears anonymous
	killmails 98007161 	#ssc
	killmails 98319972	#COF
	killmails 98295291	#half massed
	killmails 98180710	#low class
	killmails 98341909	#redfire
	killmails 98031737	#skyfighters
	killmails 98413418	#bros before holes
	killmails 98192873	#enigma 13
	killmails 1160301547	#ministry of footwork
	killmails 98332358	#mind collapse
	killmails 98170031	#desolate order

  sleep 300
done
