const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const apicache = require('apicache')
const helmet = require('helmet')
const axios = require('axios')

const instance = axios.create({
  baseURL: 'https://magnetis.com.br',
});

const app = express()

app.use(helmet())
app.use(cors())
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(apicache.middleware('5 minutes'))

app.get('/api/portfolio_summary/:id', async (req, res, next) => {
  try {
    const result = await instance
        .get(`api/portfolio_summary/${req.params.id}`, {
          headers: {
            'Authorization': req.headers.authorization || '',
            'Accept': req.headers.accept || 'application/json'
          }
        })
        .then(({ data }) => ({
          name: data.user_name,
          amount: data.portfolio_amount,
          gains: data.return.gains,
          percentage: data.return.percentage
        }))
    res.status(200).send(result)
  } catch (e) {
    next(e)
  }
})

app.post('/api/v1/users/tokens', async (req, res, next) => {
    try {
      const { email, password } = req.body
      const { data } = await instance
        .post(`api/v1/users/tokens`, {
          email,
          password
        })

      res.status(200).send({token: data.auth_token, id: data.user_id});
    } catch (e) {
      next(e)
    }
  })

app.listen(4000, (err) => {
  if (err) console.error(err)
  else console.log(`Serving on 4000`)
})