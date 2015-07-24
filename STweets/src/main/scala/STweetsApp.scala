import org.apache.spark.SparkConf
import org.apache.spark.streaming.twitter.TwitterUtils
import org.apache.spark.streaming.{Seconds, StreamingContext}

import scalaj.http.{Http, HttpOptions}

/**
 * Created by pradyumnad on 07/07/15.
 */
object STweetsApp {

//  def postData(): Unit = {
//    val response: HttpResponse[String] = Http("http://foo.com/search").param("q","monkeys").asString
//    response.body
//    response.code
//    response.headers
//  }

  def main(args: Array[String]) {
    StreamingExamples.setStreamingLogLevels()

    val filters = args

    // Set the system properties so that Twitter4j library used by twitter stream
    // can use them to generate OAuth credentials

    System.setProperty("twitter4j.oauth.consumerKey", "XmuCJg6wqok0kM4atoBWyzX70")
    System.setProperty("twitter4j.oauth.consumerSecret", "M791X1Py0jy52DG2f18EsxS0CYaMJhOfEZykO8H3mOLmfMXOBD")
    System.setProperty("twitter4j.oauth.accessToken", "66398818-wqoEXxQRTtb5GS24eqvn4DS5yQHIfay0NkgN3YDed")
    System.setProperty("twitter4j.oauth.accessTokenSecret", "xP3IHuIaGJAuDES88Mt6TuxVEz3oSDz5AlYOgtZ7MEZD1")

    //Create a spark configuration with a custom name and master
    // For more master configuration see  https://spark.apache.org/docs/1.2.0/submitting-applications.html#master-urls
    val sparkConf = new SparkConf().setAppName("STweetsApp").setMaster("local[*]")
    //Create a Streaming COntext with 2 second window
    val ssc = new StreamingContext(sparkConf, Seconds(2))
    //Using the streaming context, open a twitter stream (By the way you can also use filters)
    //Stream generates a series of random tweets
    val stream = TwitterUtils.createStream(ssc, None, filters)

    //Map : Retrieving Hash Tags
    val hashTags = stream.flatMap(status => status.getText.split(" ").filter(_.startsWith("#")))

    //Finding the top hash Tags on 30 second window
    val topCounts30 = hashTags.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(30))
      .map{case (topic, count) => (count, topic)}
      .transform(_.sortByKey(false))
    //Finding the top hash Tgas on 10 second window
    val topCounts10 = hashTags.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(10))
      .map{case (topic, count) => (count, topic)}
      .transform(_.sortByKey(false))

    // Print popular hashtags
    topCounts30.foreachRDD(rdd => {
      val topList = rdd.take(10)
      println("\nPopular topics in last 30 seconds (%s total):".format(rdd.count()))
      topList.foreach{case (count, tag) => println("%s (%s tweets)".format(tag, count))}
    })

    topCounts10.foreachRDD(rdd => {
      val topList = rdd.take(10)
      println("\nPopular topics in last 10 seconds (%s total):".format(rdd.count()))
      topList.foreach{case (count, tag) => println("%s (%s tweets)".format(tag, count))}
    })

//   // val results=Http("https://api.mongolab.com/api/1/databases/cs590bd/collections/TwitterData?apiKey=FqMHhDW_NfxEBuo6BZ67IlskGbAAdr2Z").postForm(Seq("name" -> "jon", "age" -> "29")).asString
//   val request=Http("https://api.mongolab.com/api/1/databases/cs590bd/collections/TwitterData?apiKey=FqMHhDW_NfxEBuo6BZ67IlskGbAAdr2Z").postForm(Seq("name" -> "jon", "age" -> "29")).asString
//    println("\nResponse from POST :",request);
val jsonHeaders = """{"jsonrpc": "2.0", "method": "someMethod", "params": {"dataIds":["12348" , "456"]}, "data2": "777"}"""

    val result = Http("https://api.mongolab.com/api/1/databases/cs590bd/collections/TwitterData?apiKey=FqMHhDW_NfxEBuo6BZ67IlskGbAAdr2Z").postData(jsonHeaders)
      .header("content-type", "application/json")
      .header("X-Application", "myCode")
      .header("X-Authentication", "myCode2")
      .option(HttpOptions.readTimeout(10000))
      .asString
    //.responseCode -- the same error

    println(result)
     ssc.start()

    ssc.awaitTermination()
  }
}
