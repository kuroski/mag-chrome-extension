/**
mutation {
  login(email: "*****", password: "*****") {
    token
    id
  }
}

query {
  summary(id: ****) {
    name, amount, gains, percentage
  }
}
 */
const { GraphQLServer } = require('graphql-yoga')
const axios = require('axios')

const instance = axios.create({
  baseURL: 'https://magnetis.com.br',
});

// 1
const typeDefs = `
type Query {
  summary(token: String!, id: Int!): Summary!
}

type Mutation {
  login(email: String!, password: String!): AuthPayload!
}

type Summary {
  name: String!
  amount: Float!
  gains: Float!
  percentage: Float!
}

type AuthPayload {
  token: String!
  id: Int!
}
`

// 2
const resolvers = {
  Query: {
    summary: (_, {id, token}) => {
      return instance
        .get(`api/portfolio_summary/${id}`, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })
        .then(({ data }) => ({
          name: data.user_name,
          amount: data.portfolio_amount,
          gains: data.return.gains,
          percentage: data.return.percentage
        }))
    }
  },
  Mutation: {
    async login (_, {email, password}) {
      const { data } = await instance
        .post(`api/v1/users/tokens`, {
          email,
          password
        })

      return {token: data.auth_token, id: data.user_id}
    },
  }
}

// 3
const server = new GraphQLServer({
  typeDefs,
  resolvers,
})

server
  .start(
    () => console.log(`Server is running on http://localhost:4000`))