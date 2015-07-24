import org.apache.spark.SparkConf
import org.apache.spark.streaming.twitter.TwitterUtils
import org.apache.spark.streaming.{Seconds, StreamingContext}

import scalaj.http.{Http, HttpOptions}

/**
 * Created by Jeff Lanning on 07/07/15.
 */
object PG6_SparkTweetsApp {
  def main(args: Array[String]) {
    PG6_ScalaHelper.setStreamingLogLevels()

    val filters = Array("#kc", "#kcpolice", "#kcmo", "#kansascity", "#UMKC_SG3")

    // Set the system properties so that Twitter4j library used by twitter stream
    // can use them to generate OAuth credentials
    System.setProperty("twitter4j.oauth.consumerKey", "K5irO3T6OnBimYiLwKI1aDPv0")
    System.setProperty("twitter4j.oauth.consumerSecret", "sswoK3Dgjpr17AAUaWlQyfLdFpA0ENEs11wDoCQ2ahghcAaZvu")
    System.setProperty("twitter4j.oauth.accessToken", "3248175864-yiPSna2GQo0b3WHUSHPWeFl0kHjmb4zBPy648A4")
    System.setProperty("twitter4j.oauth.accessTokenSecret", "ZAVqYA8UTavzk0gg9I1ksthmq404LZtsoXvpbFuLBHJwr")

    // Create a spark configuration with a custom name and master
    // For more master configuration see  https://spark.apache.org/docs/1.4.0/submitting-applications.html#master-urls
    val sparkConf = new SparkConf().setAppName("PG6_SparkTweetsApp").setMaster("local[*]")

    //Create a Streaming Context with 2 second window
    val ssc = new StreamingContext(sparkConf, Seconds(2))

    // Using the streaming context, open a twitter stream (By the way you can also use filters)
    // Stream generates a series of random tweets
    val stream = TwitterUtils.createStream(ssc, None, filters)

    var jsonTopics = Array[String]()
    var jsonStatuses = Array[String]()
    var jsonPlaces = Array[String]()

    // Map : Statuses
    val statuses = stream.map(status => status.getText())
    statuses.print()

    val topStatuses10 = statuses.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(10))
      .map { case (tweet, count) => (count, tweet) }
      .transform(_.sortByKey(false))

    // Finding the top Statuses on 10 second window
    topStatuses10.foreachRDD(rdd => {
      jsonStatuses = Array[String]()
      val topList = rdd.take(10)
      println("\nPopular Statuses in last 10 seconds (%s total):".format(rdd.count()))
      topList.foreach { case (count, tag) => println("%s (%s statuses)".format(tag, count)) }

      topList.foreach {
        case (count, tag) =>
          val jsonStatus = """%s: """.format(tag) + """%s (statuses)""".format(count)
          jsonStatuses = jsonStatuses :+ jsonStatus
      }
    })

    // Map : Places
    val places = stream.map(place => place.getPlace())
    places.print()

    val topPlaces10 = places.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(10))
      .map { case (place, count) => (count, place) }
      .transform(_.sortByKey(false))

    // Finding the top Places on 10 second window
    topPlaces10.foreachRDD(rdd => {
      jsonPlaces = Array[String]()
      val topList = rdd.take(10)
      println("\nPopular Places in last 10 seconds (%s total):".format(rdd.count()))
      topList.foreach { case (count, tag) => println("%s (%s places)".format(tag, count)) }

      topList.foreach {
        case (count, tag) =>
          val jsonPlace = """%s: """.format(tag) + """%s (places)""".format(count)
          jsonPlaces = jsonPlaces :+ jsonPlace
      }
    })

    // Map : Words
    val words = stream.flatMap(word => word.getText.split(" "))

    // Map : Retrieving Hash Tags
    val hashTags = words.filter(_.startsWith("#"))

    // Finding the top hash Tags on 10 second window
    val topCounts10 = hashTags.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(10))
      .map { case (topic, count) => (count, topic) }
      .transform(_.sortByKey(false))

    topCounts10.foreachRDD(rdd => {
      jsonTopics = Array[String]()
      val topList = rdd.take(10)
      println("\nPopular topics in last 10 seconds (%s total):".format(rdd.count()))
      topList.foreach { case (count, tag) => println("%s (%s tweets)".format(tag, count)) }

      topList.foreach {
         case (count, tag) =>
           val jsonTopic = """%s: """.format(tag) + """%s (tweets)""".format(count)
           jsonTopics = jsonTopics :+ jsonTopic
      }

      if (!jsonTopics.isEmpty) {

        var jsonTopicItems = ""
        var topicsIdx = 1
        jsonTopics.foreach {
          case (topic) =>
            jsonTopicItems += topic
            if (topicsIdx < jsonTopics.length) {
              jsonTopicItems += ","
            }
            topicsIdx += 1
        }

        var jsonStatusItems = ""
        if (!jsonStatuses.isEmpty) {
          var statusIdx = 1
          jsonStatuses.foreach {
            case (status) =>
              jsonStatusItems += status
              if (statusIdx < jsonStatuses.length) {
                jsonStatusItems += ","
              }
              statusIdx += 1
          }
        }

        var jsonPlaceItems = ""
        if (!jsonPlaces.isEmpty) {
          var placeIdx = 1
          jsonPlaces.foreach {
            case (place) =>
              jsonPlaceItems += place
              if (placeIdx < jsonPlaces.length) {
                jsonPlaceItems += ","
              }
              placeIdx += 1
          }
        }

        val jsonHeaders = """{"topTopics":[""".concat( """"""").concat(jsonTopicItems).concat( """"""").concat( """]""")
                  .concat(""","topStatuses":[""").concat( """"""").concat(jsonStatusItems).concat( """"""").concat( """]""")
                  .concat(""","topPlaces":[""").concat( """"""").concat(jsonPlaceItems).concat( """"""").concat( """]}""")
        println("\nTwitter Data Request to MongoDB: %s".format(jsonHeaders))

        val url = "https://api.mongolab.com/api/1/databases/cs590_sg3/collections/TwitterData?apiKey=j-xyG_r8AOd5fKxRNNGlmsS9vradUXAU"
        val result = Http(url).postData(jsonHeaders)
          .header("content-type", "application/json")
          .header("X-Application", "myCode")
          .header("X-Authentication", "myCode2")
          .option(HttpOptions.connTimeout(10000)).option(HttpOptions.readTimeout(50000))
          .asString

        println("\n" + result)
      }
    })

    ssc.start()

    ssc.awaitTermination()
  }
}
