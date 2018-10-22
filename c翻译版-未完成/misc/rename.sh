for file in `find`; do
	str=`echo $file | tr 'A-Z' 'a-z'`
	mv $file $str
done
