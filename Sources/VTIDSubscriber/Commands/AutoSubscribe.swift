//
//  AutoSubscribe.swift
//  
//
//  Created by Bunga Mungil on 03/07/23.
//

import ImperialGoogle
import Vapor
import WebSubSubscriber


struct AutoSubscribe: Command {
    
    struct Signature: CommandSignature {
        
        @Option(name: "bearer-token")
        var bearerToken: String?
        
    }
    
    var help: String = "Auto subscribe from Vtuber Asia's spreadsheet"
    
    func run(using context: CommandContext, signature: Signature) throws {
        let promise = context
            .application
            .eventLoopGroup
            .next()
            .makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.run(using: context, signature: signature)
        }
        try promise.futureResult.wait()
    }
    
}


extension AutoSubscribe {
    
    fileprivate func run(using context: CommandContext, signature: Signature) async throws {
        let accessToken = signature.bearerToken ?? context.console.ask("Bearer Token : ")
        let sheet = try await self.fetchVtuberAsiaSpreadsheet(using: context, with: accessToken)
        let channelIDs = self.parseChannelIDs(from: sheet)
        for channelID in channelIDs {
            try await channelID.handle(on: context, then: { ctx, useCase in
                try await useCase.handle(on: context) { ctx, subscription in
                    try await SubscribeRequestToHub(
                        mode: subscription.0,
                        subscription: subscription.1
                    ).handle(on: context, then: { ctx, request in
                        let response = try await context.application.client.post(
                            request.0,
                            beforeSend: request.1
                        )
                        context.console.print(
                            """
                            Request  : \(request.0)
                            Response : \(response.status.code)
                            """
                        )
                    })
                }
            })
        }
    }
    
    fileprivate func fetchVtuberAsiaSpreadsheet(using context: CommandContext, with accessToken: String) async throws -> SpreadsheetValuesResponse {
        let sheet = try await context.application.client
            .get("https://sheets.googleapis.com/v4/spreadsheets/\(Environment.get("SPREADSHEET_ID") ?? "")/values/\(Environment.get("SPREADSHEET_RANGE") ?? "")") { outgoingReq in
                outgoingReq.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
        }
        return try sheet.content.decode(SpreadsheetValuesResponse.self)
    }
    
    fileprivate func parseChannelIDs(from spreadsheet: SpreadsheetValuesResponse) -> [String] {
        let values = spreadsheet.values
        return values[2 ..< values.count].flatMap { value in
            if value.count > 13 && value[12] == "GRADUATED" {
                return [] as [String]
            }
            if value.count > 1 && !value[0].isEmpty {
                return [value[0]]
            }
            return [] as [String]
        }
    }
    
}


extension String: CommandHandler {
    
    public typealias ResultType = SubscribeRequestUseCases
    
    public func handle(on ctx: CommandContext) async -> Result<SubscribeRequestUseCases, ErrorResponse> {
        return .success(.subscribeWithPreferredHub(
            topic: "https://www.youtube.com/xml/feeds/videos.xml?channel_id=\(self)",
            hub: "https://pubsubhubbub.appspot.com",
            leaseSeconds: nil
        ))
    }
    
}


extension AutoSubscribe: SubscribingFromCommand { }
