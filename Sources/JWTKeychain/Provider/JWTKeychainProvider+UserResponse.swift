import JWT
import Sugar
import Vapor

extension JWTKeychainProvider {
    /// Makes UserResponse value containing (all optional, depending on the `options` parameter):
    ///   - a publically safe representation of the user
    ///   - an access token
    ///   - a refresh token
    ///
    /// - Parameters:
    ///   - user: the user for which the generate the tokens
    ///   - options: determines which of the values to include in the response
    ///   - req: the current request
    /// - Returns: a future UserResponse value containing the requested values
    public func makeUserResponse(
        for user: U,
        withOptions options: UserResponseOptions,
        on req: Request
    ) throws -> Future<UserResponse<U>> {
        let now = Date()

        func signIfPresent(
            using signer: ExpireableJWTSigner?,
            on worker: Worker
        ) throws -> Future<String?> {
            guard let signer = signer else {
                return Future.map(on: worker) { nil }
            }
            return try user.signToken(using: signer, currentTime: now, on: req).map(Optional.init)
        }

        let accessTokenSigner = options.contains(.accessToken) ? config.accessTokenSigner : nil
        let refreshTokenSigner = options.contains(.refreshToken) ? config.refreshTokenSigner : nil

        return try map(
            to: UserResponse<U>.self,
            signIfPresent(using: accessTokenSigner, on: req),
            signIfPresent(using: refreshTokenSigner, on: req)
        ) { (accessToken, refreshToken) in
            UserResponse(
                user: options.contains(.user) ? user : nil,
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }
    }
}
