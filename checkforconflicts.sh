#!/bin/bash

#скрипт не отработает если коммит уже добавлен!!!
#
#эта строка была заменена в связи с реализацией использования UTF8 в *.properties файлах в master_test
#в формате задачи-37169 от 29.01.2017
#egrep -v '(localization)|(target)|(_[a-zA-Z]{2}.properties)|(plugin.properties)'
# Convert configuration *.properties to native format
#find /home//Development//panbet -name .properties | grep -v "plugin.*\.properties" | egrep "^\s+" | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file
#do
# native2ascii -encoding utf8 -reverse "$file" "$file"
#done
#=======================================================
git status | grep -v 'deleted' | grep '.properties' | grep -v "plugin.*\.properties" | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file
do
        echo -n "Converting $file... "
        native2ascii -encoding utf8 -reverse "$file" "$file"
        echo "Done"
done
#=======================================================
# Convert to unix format
git status | grep -v 'deleted' | fgrep ':   ' | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file; 
do
	dos2unix -q $file
done
#Наличие строк с неверной кодировкой
if grep -R -c '\u0' /resources/dbupdates.properties --color
#if grep -v plugin.*\.properties --color
then
        echo "Строк с невернной кодировкой 
Кажется это тарбол.!"
else
        echo "Строк с невернной кодировкой
Все пучком.)"
fi
# Search for wrong registry bundles
git status | grep '\.properties' | grep -v target | grep resources | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file
do
    sed -i -r 's|(\\u[0-9A-F]{4})|\L\1|g' $file
done
# Convert dbupdates.properties to native format
#add home/../resources/
git status | grep dbupdates.properties && native2ascii -reverse -encoding utf-8 dbupdates.properties dbupdates.utf8
# Search for conflicts
git status | fgrep ':   ' | grep -v 'deleted' | fgrep -v -- '->' | cut -f2 -d ':' | sed -r 's|^\s+||' | while read file; do
	fgrep -R '<<<<<<<' $file && continue || \
	fgrep -R '>>>>>>>' $file | fgrep -v '>>>>>>>>>>>>>' && continue || \
	fgrep -R '=======' $file | fgrep -v '========' | fgrep -v 'n=======' && continue || git add $file
done
# Convert configuration *.properties to native format
# git status | grep '.properties' | egrep -v '(localization)|(target)|(_[a-zA-Z]{2}.properties)|(plugin.properties)' | egrep "^\s+" | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file
# do
# native2ascii -encoding utf8 -reverse "$file" "$file"
# done
# Convert dbupdates.properties to native format
#### git status | grep /home//Development////resources/dbupdates.properties && native2ascii -reverse -encoding utf-8 /home//Development////resources/dbupdates.properties dbupdates.utf8
# Convert to unix format
# git status | grep -v 'deleted' | fgrep ': ' | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file; do
# dos2unix -q "$file"
# done
# Convert to unix format
#git status | grep -v 'удалено' | fgrep ':   ' | cut -f2 -d ':' | sed -r 's|^\s+||' | sed -r 's|^.*->\ (.*)|\1|' | while read file; 
#do
#dos2unix -q $file
#done
# Search for conflicts
#git status | fgrep ':   ' | grep -v 'удалено' | fgrep -v -- '->' | cut -f2 -d ':' | sed -r 's|^\s+||' | while read file; do
#	fgrep -R '<<<<<<<' $file && continue || \
#	fgrep -R '>>>>>>>' $file | fgrep -v '>>>>>>>>>>>>>' && continue || \
#	fgrep -R '=======' $file | fgrep -v '========' | fgrep -v 'n=======' && continue || git add $file
#done
# комменттируй каждую строку !!!
# parametr1=$1 #присваиваем переменной parametr1 значение первого параметра скрипта
# script_name=$0 #присваиваем переменной script_name значение имени скрипта
#if grep -R -c '\u0' ejbPanbet/resources/dbupdates.properties --color
#then 
#** gsed разобрать и адаптироовать 
