import JWT
import Vapor

public struct UserResponseOptions: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int

    public static let user          = UserResponseOptions(rawValue: 1 << 0)
    public static let accessToken   = UserResponseOptions(rawValue: 1 << 0)
    public static let refreshToken  = UserResponseOptions(rawValue: 1 << 0)

    public static let all: UserResponseOptions = [.user, .accessToken, .refreshToken]
}

public struct UserResponse<U: PublicRepresentable>: Content {
    let user: U.Public?
    let accessToken: String?
    let refreshToken: String?

    public init(user: U?, accessToken: String? = nil, refreshToken: String? = nil) {
        self.user = user?.convertToPublic()
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - JWTKeychainProvider + UserResponse

extension JWTKeychainProvider {
    public func makeUserResponse(
        for user: U,
        withOptions options: UserResponseOptions,
        on req: Request
    ) -> Future<UserResponse<U>> {
        let now = Date()

        func sign(using signer: ExpireableJWTSigner?) -> Future<String?> {
            guard let signer = signer else {
                return Future.map(on: req) { nil }
            }
            return Future
                .flatMap(on: req) { () -> Future<String?> in
                    user.makePayload(expirationTime: now + signer.expirationPeriod, on: req)
                        .map(to: String?.self) {
                            var jwt = JWT<U.JWTPayload>(payload: $0)
                            return try jwt.sign(using: signer.signer).base64URLEncodedString()
                        }
                }
        }

        return map(
            to: UserResponse<U>.self,
            sign(using: options.contains(.accessToken) ? config.accessTokenSigner : nil),
            sign(using: options.contains(.refreshToken) ? config.refreshTokenSigner : nil)
        ) { (accessToken, refreshToken) in
            UserResponse(
                user: options.contains(.user) ? user : nil,
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }
    }
}