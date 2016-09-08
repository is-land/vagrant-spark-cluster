val words = Seq("copyright", "permission", "software")

val lines = sc.textFile("/vagrant/data/licenses/*.txt")

val counts = lines.flatMap(line=>line.split(" "))
                  .filter( w=>words.contains(w.toLowerCase) )
                  .map( (_, 1) )
                  .reduceByKey( _ + _ )

val result = counts.collect()