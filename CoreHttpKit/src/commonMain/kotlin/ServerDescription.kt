package org.cottonweb.CoreHttpKit

enum class HttpScheme(val stringValue: String, val port: Int) {
    https("https", 443),
    http("http", 80);

    companion object {
        fun create(rawString: String): HttpScheme? {
            return when (rawString) {
                "https" -> https
                "http" -> http
                else -> null
            }
        }
    }
}

// https://blog.kotlin-academy.com/abstract-class-vs-interface-in-kotlin-5ab8697c3a14

/**
 * A server description base interface
 *
 * @property host A host name (usually domain name and not an ip address)
 * @property scheme Server protocol type (could be HTTPS, HTTP, etc.)
 * */
open class ServerDescription(val host: Host, val scheme: HttpScheme = HttpScheme.https)
