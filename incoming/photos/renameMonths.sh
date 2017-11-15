#!/bin/bash

for D in ${1:-*}; do
	case "$D" in
		*January*)  dd=01; month=January;;
		*Jan*)      dd=01; month=Jan;;
		*February*) dd=02; month=February;;
		*Feb*)      dd=02; month=Feb;;
		*March*)    dd=03; month=March;;
		*April*)    dd=04; month=April;;
		*May*)      dd=05; month=May;;
		*June*)     dd=06; month=June;;
		*July*)     dd=07; month=July;;
		*August*)   dd=08; month=August;;
		*September*)dd=09; month=September;;
		*Sept*)     dd=09; month=Sept;;
		*Sep*)      dd=09; month=Sep;;
		*October*)  dd=10; month=October;;
		*Oct*)      dd=10; month=Oct;;
		*November*) dd=11; month=November;;
		*Nov*)      dd=11; month=Nov;;
		*December*) dd=12; month=December;;
		*Dec*)      dd=12; month=Dec;;
	esac
	#newname="${D/$month/-$dd}";
	newname="$2-$dd";
	echo "mv $D $newname"
done

