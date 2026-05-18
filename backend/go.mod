module prism/backend

go 1.25.6

require github.com/go-sql-driver/mysql v1.9.3

require filippo.io/edwards25519 v1.1.0 // indirect

replace github.com/go-sql-driver/mysql => ./third_party/mysql

replace filippo.io/edwards25519 => ./third_party/edwards25519
