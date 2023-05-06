for f in ./*/*;do
    if [[ $f = .*md ]];then
	base=$(basename $f .md)
	#echo $base
	categories=$(basename $(dirname $f) $PWD)
	insert="---\ntitle: ${base}\ncategories:\n- ${categories}\n---\n"
	echo -e "${insert}$(cat $f)" > $f
    fi
done
