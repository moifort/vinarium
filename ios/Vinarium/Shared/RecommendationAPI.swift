import Apollo
import Foundation

enum RecommendationAPI {
    static func create(wineId: String, recommenderName: String?, comment: String?) async throws {
        let input = VinariumGraphQL.RecommendationInput(
            comment: GraphQLHelpers.graphQLNullable(comment),
            recommenderName: GraphQLHelpers.graphQLNullable(recommenderName)
        )
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.AddRecommendationMutation(wineId: wineId, input: input)
        )
    }
}
