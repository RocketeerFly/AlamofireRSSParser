//
//  AlamofireRSSParser.swift
//  Pods
//
//  Created by Donald Angelillo on 3/2/16.
//
//

import Foundation
import Alamofire

extension Alamofire.DataRequest {
    /**
        Creates a response serializer that returns an `RSSFeed` object initialized from the response data.
     
        - Returns: An RSS response serializer.
     */
    public static func RSSResponseSerializer() -> DataResponseSerializer<RSSFeed> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .failure(error!)
            }
            
            guard let validData = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = NSError(domain: "com.alamofirerssparser", code: -6004, userInfo: [NSLocalizedFailureReasonErrorKey: failureReason])
                return .failure(error)
            }
            
            let parser = AlamofireRSSParser(data: validData)
            
            let parsedResults: (feed: RSSFeed?, error: NSError?) = parser.parse()
            
            if let feed = parsedResults.feed {
                return .success(feed)
            } else {
                return .failure(parsedResults.error!)
            }
        }
    }
    
    
    /**
        Adds a handler to be called once the request has finished.
        
        - Parameter completionHandler: A closure to be executed once the request has finished.
    
        - Returns: The request.
    */
    @discardableResult
    public func responseRSS(_ completionHandler: @escaping (DataResponse<RSSFeed>) -> Void) -> Self {
        return response(
            responseSerializer: DataRequest.RSSResponseSerializer(),
            completionHandler: completionHandler
        )
    }
    
    
    //public func responseRSS(parser parser: AlamofireRSSParser?, completionHandler: Response<RSSFeed, NSError> -> Void) -> Self {
    //  return response(responseSerializer: Request.RSSResponseSerializer(parser), completionHandler: completionHandler)
    //}
}


/**
    This class does the bulk of the work.  Implements the `NSXMLParserDelegate` protocol.
    Unfortunately due to this it's also required to implement the `NSObject` protocol.
    
    And unfortunately due to that there doesn't seem to be any way to make this class have a valid public initializer,
    despite it being marked public.  I would love to have it be publicly accessible because I would like to able to pass
    a custom-created instance of this class with configuration properties set into `responseRSS` (see the commented out overload above)
*/
open class AlamofireRSSParser: NSObject, XMLParserDelegate {
    var parser: XMLParser? = nil
    var feed: RSSFeed? = nil
    var parsingItems: Bool = false
    
    var currentItem: RSSItem? = nil
    var currentString: String!
    var currentAttributes: [String: String]? = nil
    var parseError: NSError? = nil
    
    open var data: Data? = nil {
        didSet {
            if let data = data {
                self.parser = XMLParser(data: data)
                self.parser?.delegate = self
            }
        }
    }
    
    override init() {
        self.parser = XMLParser();
        
        super.init()
    }
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        
        self.parser?.delegate = self
    }
    
    
    /**
        Kicks off the RSS parsing.
     
        - Returns: A tuple containing an `RSSFeed` object if parsing was successful (`nil` otherwise) and
            an `NSError` object if an error occurred (`nil` otherwise).
    */
    func parse() -> (feed: RSSFeed?, error: NSError?) {
        self.feed = RSSFeed()
        self.currentItem = nil
        self.currentAttributes = nil
        self.currentString = String()
        
        self.parser?.parse()
        return (feed: self.feed, error: self.parseError)
    }
    
    //MARK: - NSXMLParserDelegate
    open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentString = String()
        
        self.currentAttributes = attributeDict
        
        if ((elementName == "item") || (elementName == "entry")) {
            self.currentItem = RSSItem()
        }
    }
    
    open func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        //if we're at the item level
        if let currentItem = self.currentItem {
            if ((elementName == "item") || (elementName == "entry")) {
                self.feed?.items.append(currentItem)
                return
            }
            
            if (elementName == "title") {
                currentItem.title = self.currentString
            }
            
            if (elementName == "description") {
                currentItem.itemDescription = self.currentString
            }
            
            if ((elementName == "content:encoded") || (elementName == "content")) {
                currentItem.content = self.currentString
            }
            
            if (elementName == "link") {
                currentItem.link = self.currentString
            }
            
            if (elementName == "guid") {
                currentItem.guid = self.currentString
            }
            
            if (elementName == "author") {
                currentItem.author = self.currentString
            }
            
            if (elementName == "comments") {
                currentItem.comments = self.currentString
            }
            
            if (elementName == "source") {
                currentItem.source = self.currentString
            }
            
            if (elementName == "pubDate") {
                currentItem.pubDate = self.currentString
            }
            
            if (elementName == "published") {
                currentItem.pubDate = self.currentString
            }
            
            if (elementName == "media:thumbnail") {
                if let attributes = self.currentAttributes {
                    if let url = attributes["url"] {
                        currentItem.mediaThumbnail = url
                    }
                }
            }
            
            if (elementName == "media:content") {
                if let attributes = self.currentAttributes {
                    if let url = attributes["url"] {
                        currentItem.mediaContent = url
                    }
                }
            }
            
            if (elementName == "enclosure") {
                if let attributes = self.currentAttributes {
                    currentItem.enclosures = (currentItem.enclosures ?? []) + [attributes]
                }
            }
            
            if (elementName == "category") {
                if let attributes = self.currentAttributes {
                    currentItem.categories = (currentItem.categories ?? []) + [attributes]
                }
            }
            
            
        //if we're at the top level
        } else {
            if (elementName == "title") {
                self.feed?.title = self.currentString
            }
            
            if (elementName == "description") {
                self.feed?.feedDescription = self.currentString
            }
            
            if (elementName == "link") {
                self.feed?.link = self.currentString
            }
            
            if (elementName == "language") {
                self.feed?.language = self.currentString
            }
            
            if (elementName == "copyright") {
                self.feed?.copyright = self.currentString
            }
            
            if (elementName == "managingEditor") {
                self.feed?.managingEditor = self.currentString
            }
            
            if (elementName == "webMaster") {
                self.feed?.webMaster = self.currentString
            }
            
            if (elementName == "generator") {
                self.feed?.generator = self.currentString
            }
            
            if (elementName == "docs") {
                self.feed?.docs = self.currentString
            }
            
            if (elementName == "ttl") {
                if let ttlInt = Int(currentString) {
                    self.feed?.ttl = NSNumber(value: ttlInt)
                }
            }
            
            if (elementName == "pubDate") {
                self.feed?.pubDate = self.currentString
            }
            
            if (elementName == "published") {
                self.feed?.pubDate = self.currentString
            }
            
            if (elementName == "lastBuildDate") {
                if let date = RSSDateFormatter.rfc822DateFormatter().date(from: self.currentString) {
                    self.feed?.lastBuildDate = date
                } else if let date = RSSDateFormatter.rfc822DateFormatter2().date(from: self.currentString) {
                    self.feed?.lastBuildDate = date
                }
            }
        }
    }
    
    open func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.currentString.append(string)
    }
    
    open func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError as NSError?
        self.parser?.abortParsing()
    }
}

/**
    Struct containing various `NSDateFormatter` s
*/
struct RSSDateFormatter {
    static func rfc822DateFormatter() -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return dateFormatter
    }
    
    static func rfc822DateFormatter2() -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return dateFormatter
    }
    
    static func publishedDateFormatter() -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
    
    static func publishedDateFormatter2() -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
        return dateFormatter
    }
}
