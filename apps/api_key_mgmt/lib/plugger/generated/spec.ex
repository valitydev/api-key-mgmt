defmodule Plugger.Generated.Spec do
  @moduledoc false
  @openapi_spec %OpenApiSpex.OpenApi{
    openapi: "3.0.3",
    info: %OpenApiSpex.Info{
      title: "Vality API Keys Management API",
      description:
        "Vality API Keys Management API является интерфейсом для управления набором\nAPI-ключей, используемых для авторизации запросов к основному API с ваших\nбэкенд-сервисов. Любые сторонние приложения, включая ваш личный кабинет,\nявляются внешними приложениями-клиентами данного API.\n\nМы предоставляем REST API поверх HTTP-протокола, схема которого описывается в\nсоответствии со стандартом [OpenAPI 3][OAS3].\nКоды возврата описываются соответствующими HTTP-статусами. Платформа принимает и\nвозвращает значения JSON в теле запросов и ответов.\n\n[OAS3]: https://swagger.io/specification/\n\n## Формат содержимого\n\nЛюбой запрос к API должен выполняться в кодировке UTF-8 и с указанием\nсодержимого в формате JSON.\n\n```\nContent-Type: application/json; charset=utf-8\n```\n",
      termsOfService: "https://vality.dev/",
      license: %OpenApiSpex.License{
        name: "Apache 2.0",
        url: "https://www.apache.org/licenses/LICENSE-2.0.html"
      },
      version: "1.0.0"
    },
    servers: [],
    paths: %{
      "/orgs/{partyId}/api-keys" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["apiKeys"],
          summary: "Перечислить ключи организации",
          operationId: "listApiKeys",
          parameters: [
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/partyId"},
            %OpenApiSpex.Parameter{
              name: :status,
              in: :query,
              description: "Фильтр по статусу ключа. По умолчанию `active`.\n",
              required: false,
              schema: %OpenApiSpex.Reference{
                "$ref": "#/components/schemas/ApiKeyStatus"
              }
            }
          ],
          responses: %{
            "200" => %OpenApiSpex.Response{
              description: "Ключи найдены",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: %OpenApiSpex.Schema{
                    properties: %{
                      results: %OpenApiSpex.Schema{
                        items: %OpenApiSpex.Reference{
                          "$ref": "#/components/schemas/ApiKey"
                        },
                        type: :array
                      }
                    },
                    required: [:results],
                    type: :object
                  }
                }
              }
            },
            "400" => %OpenApiSpex.Reference{
              "$ref": "#/components/responses/BadRequest"
            },
            "403" => %OpenApiSpex.Response{
              description: "Операция недоступна"
            }
          },
          callbacks: %{},
          deprecated: false
        },
        post: %OpenApiSpex.Operation{
          tags: ["apiKeys"],
          summary: "Выпустить новый ключ",
          operationId: "issueApiKey",
          parameters: [
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/partyId"}
          ],
          requestBody: %OpenApiSpex.RequestBody{
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: %OpenApiSpex.Reference{
                  "$ref": "#/components/schemas/ApiKey"
                }
              }
            },
            required: false
          },
          responses: %{
            "200" => %OpenApiSpex.Response{
              description: "Ключ выпущен",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: %OpenApiSpex.Schema{
                    allOf: [
                      %OpenApiSpex.Reference{
                        "$ref": "#/components/schemas/ApiKey"
                      },
                      %OpenApiSpex.Reference{
                        "$ref": "#/components/schemas/AccessToken"
                      }
                    ]
                  }
                }
              }
            },
            "400" => %OpenApiSpex.Reference{
              "$ref": "#/components/responses/BadRequest"
            },
            "403" => %OpenApiSpex.Response{
              description: "Операция недоступна"
            }
          },
          callbacks: %{},
          deprecated: false
        }
      },
      "/orgs/{partyId}/api-keys/{apiKeyId}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["apiKeys"],
          summary: "Получить данные ключа",
          operationId: "getApiKey",
          parameters: [
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/partyId"},
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/apiKeyId"}
          ],
          responses: %{
            "200" => %OpenApiSpex.Response{
              description: "Ключ найден",
              content: %{
                "application/json" => %OpenApiSpex.MediaType{
                  schema: %OpenApiSpex.Reference{
                    "$ref": "#/components/schemas/ApiKey"
                  }
                }
              }
            },
            "400" => %OpenApiSpex.Reference{
              "$ref": "#/components/responses/BadRequest"
            },
            "403" => %OpenApiSpex.Response{
              description: "Операция недоступна"
            },
            "404" => %OpenApiSpex.Response{
              description: "Ключ не найден"
            }
          },
          callbacks: %{},
          deprecated: false
        }
      },
      "/orgs/{partyId}/api-keys/{apiKeyId}/status" => %OpenApiSpex.PathItem{
        put: %OpenApiSpex.Operation{
          tags: ["apiKeys"],
          summary: "Запросить отзыв ключа",
          description:
            "Просит отозвать Api Key, для подтверждения запроса\nпосылает на почту запросившего письмо с ссылкой на\nrevokeApiKey для подтверждения операции\n",
          operationId: "requestRevokeApiKey",
          parameters: [
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/partyId"},
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/apiKeyId"}
          ],
          requestBody: %OpenApiSpex.RequestBody{
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: %OpenApiSpex.Schema{enum: ["Revoked"], type: :string}
              }
            },
            required: false
          },
          responses: %{
            "204" => %OpenApiSpex.Response{
              description: "Запрос на операцию получен"
            },
            "400" => %OpenApiSpex.Reference{
              "$ref": "#/components/responses/BadRequest"
            },
            "403" => %OpenApiSpex.Response{
              description: "Операция недоступна"
            },
            "404" => %OpenApiSpex.Response{
              description: "Ключ не найден"
            }
          },
          callbacks: %{},
          deprecated: false
        }
      },
      "/orgs/{partyId}/revoke-api-key/{apiKeyId}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          tags: ["apiKeys"],
          summary: "Отозвать ключ",
          description:
            "Ссылка на этот запрос приходит на почту запросившего\nrequestRevokeApiKey, в результате выполнения этого запроса\nApi Key будет отозван\n",
          operationId: "revokeApiKey",
          parameters: [
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/partyId"},
            %OpenApiSpex.Reference{"$ref": "#/components/parameters/apiKeyId"},
            %OpenApiSpex.Reference{
              "$ref": "#/components/parameters/apiKeyRevokeToken"
            }
          ],
          responses: %{
            "204" => %OpenApiSpex.Response{
              description: "Ключ отозван"
            },
            "400" => %OpenApiSpex.Reference{
              "$ref": "#/components/responses/BadRequest"
            },
            "403" => %OpenApiSpex.Response{
              description: "Операция недоступна"
            },
            "404" => %OpenApiSpex.Response{
              description: "Ключ не найден"
            }
          },
          callbacks: %{},
          deprecated: false
        }
      }
    },
    components: %OpenApiSpex.Components{
      schemas: %{
        "AccessToken" => %OpenApiSpex.Schema{
          properties: %{
            accessToken: %OpenApiSpex.Schema{
              description: "Токен доступа, ассоциированный с данным ключом",
              example:
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0a2kiOiIxS2dJWUJHc0NncSIsImlhdCI6MTUxNjIzOTAyMn0.6YsaZQC9A7BjxXHwRbJfUO6VujOb4rHTKrqmMt64TbQ\n",
              maxLength: 4000,
              minLength: 1,
              type: :string
            }
          },
          required: [:accessToken],
          type: :object
        },
        "ApiKey" => %OpenApiSpex.Schema{
          description: "Ключ для авторизации запросов к API",
          properties: %{
            createdAt: %OpenApiSpex.Schema{
              description: "Дата и время создания",
              format: :"date-time",
              readOnly: true,
              type: :string
            },
            id: %OpenApiSpex.Reference{"$ref": "#/components/schemas/ApiKeyID"},
            metadata: %OpenApiSpex.Schema{
              description:
                "Произвольный набор данных, специфичный для клиента API и\nнепрозрачный для системы\n",
              properties: %{},
              type: :object
            },
            name: %OpenApiSpex.Schema{
              description: "Запоминающееся название ключа",
              example: "live-site-integration",
              maxLength: 40,
              minLength: 1,
              type: :string
            },
            status: %OpenApiSpex.Reference{
              "$ref": "#/components/schemas/ApiKeyStatus"
            }
          },
          required: [:id, :createdAt, :name, :status],
          type: :object
        },
        "ApiKeyID" => %OpenApiSpex.Schema{
          description: "Идентификатор ключа",
          example: "1KgIYBGsCgq",
          maxLength: 40,
          minLength: 1,
          readOnly: true,
          type: :string
        },
        "ApiKeyStatus" => %OpenApiSpex.Schema{
          description: "Статус ключа",
          enum: ["Active", "Revoked"],
          readOnly: true,
          type: :string
        },
        "RevokeToken" => %OpenApiSpex.Schema{
          description: "Токен отзыва ключа, приходит с ссылкой в почте",
          example: "f767b77e-300f-47a7-84e2-e24ea585a9f0\n",
          maxLength: 4000,
          minLength: 1,
          type: :string
        }
      },
      responses: %{
        "BadRequest" => %OpenApiSpex.Response{
          description: "Переданы ошибочные данные",
          content: %{
            "application/json" => %OpenApiSpex.MediaType{
              schema: %OpenApiSpex.Schema{
                description: "Ошибка в переданных данных",
                properties: %{
                  code: %OpenApiSpex.Schema{
                    enum: ["invalidRequest"],
                    type: :string
                  },
                  message: %OpenApiSpex.Schema{type: :string}
                },
                required: [:code],
                type: :object
              }
            }
          }
        }
      },
      parameters: %{
        "apiKeyId" => %OpenApiSpex.Parameter{
          name: :apiKeyId,
          in: :path,
          description: "Идентификатор ключа",
          required: true,
          schema: %OpenApiSpex.Reference{"$ref": "#/components/schemas/ApiKeyID"}
        },
        "apiKeyRevokeToken" => %OpenApiSpex.Parameter{
          name: :apiKeyRevokeToken,
          in: :query,
          description: "Токен отзыва ключа",
          required: true,
          schema: %OpenApiSpex.Reference{
            "$ref": "#/components/schemas/RevokeToken"
          }
        },
        "partyId" => %OpenApiSpex.Parameter{
          name: :partyId,
          in: :path,
          description: "Идентификатор участника",
          required: true,
          schema: %OpenApiSpex.Schema{
            description: "Идентификатор участника",
            example: "bdaf9e76-1c5b-4798-b154-19b87a61dc94",
            maxLength: 40,
            minLength: 1,
            type: :string
          }
        }
      },
      securitySchemes: %{
        "bearer" => %OpenApiSpex.SecurityScheme{
          type: "http",
          description:
            "Для аутентификации вызовов мы используем [JWT](https://jwt.io). Токен доступа передается в заголовке.\n```shell\n Authorization: Bearer {JWT}\n```\nЗапросы к данному API авторизуются сессионным токеном доступа, который вы получаете в результате аутентификации в личном кабинете.\n",
          scheme: "bearer",
          bearerFormat: "JWT"
        }
      }
    },
    security: [%{"bearer" => []}],
    tags: [
      %OpenApiSpex.Tag{
        name: "apiKeys",
        extensions: %{"x-displayName" => "API-ключи"}
      },
      %OpenApiSpex.Tag{
        name: "errorCodes",
        description:
          "## Общие ошибки\n\nОшибки возникающие при попытках совершения недопустимых операций, операций с невалидными объектами или несуществующими ресурсами. Имеют следующий вид:\n\n```json\n{\n    \"code\": \"string\",\n    \"message\": \"string\"\n}\n```\n\nВ поле `message` содержится информация по произошедшей ошибке. Например:\n\n```json\n{\n    \"code\": \"invalidRequest\",\n    \"message\": \"Property 'name' is required.\"\n}\n```\n\n## Ошибки обработки запросов\n\nВ процессе обработки запросов силами нашей платформы могут происходить различные непредвиденные ситуации. Об их появлении платформа сигнализирует по протоколу HTTP соответствующими [статусами][5xx], обозначающими ошибки сервера.\n\n|  Код    |  Описание  |\n| ------- | ---------- |\n| **500** | В процессе обработки платформой запроса возникла непредвиденная ситуация. При получении подобного кода ответа мы рекомендуем обратиться в техническую поддержку. |\n| **503** | Платформа временно недоступна и не готова обслуживать данный запрос. Запрос гарантированно не выполнен, при получении подобного кода ответа попробуйте выполнить его позднее, когда доступность платформы будет восстановлена. |\n| **504** | Платформа превысила допустимое время обработки запроса, результат запроса не определён. Попробуйте отправить запрос повторно или выяснить результат выполнения исходного запроса, если повторное исполнение запроса нежелательно. |\n\n[5xx]: https://tools.ietf.org/html/rfc7231#section-6.6\n\n\nЕсли вы получили ошибку, которой нет в данном описании, обратитесь в техническую поддержку.\n",
        extensions: %{"x-displayName" => "Коды ошибок"}
      }
    ]
  }

  @spec get :: OpenApiSpex.OpenApi.t()
  def get do
    @openapi_spec
  end

  @spec cast_and_validate(Plug.Conn.t(), atom()) ::
          {:ok, Plug.Conn.t()} | {:error, {:invalid_request, [OpenApiSpex.Cast.Error.t()]}}
  def cast_and_validate(conn, :get_api_key) do
    do_cast_and_validate(
      conn,
      @openapi_spec.paths["/orgs/{partyId}/api-keys/{apiKeyId}"].get
    )
  end

  def cast_and_validate(conn, :issue_api_key) do
    do_cast_and_validate(
      conn,
      @openapi_spec.paths["/orgs/{partyId}/api-keys"].post
    )
  end

  def cast_and_validate(conn, :list_api_keys) do
    do_cast_and_validate(
      conn,
      @openapi_spec.paths["/orgs/{partyId}/api-keys"].get
    )
  end

  def cast_and_validate(conn, :request_revoke_api_key) do
    do_cast_and_validate(
      conn,
      @openapi_spec.paths["/orgs/{partyId}/api-keys/{apiKeyId}/status"].put
    )
  end

  def cast_and_validate(conn, :revoke_api_key) do
    do_cast_and_validate(
      conn,
      @openapi_spec.paths["/orgs/{partyId}/revoke-api-key/{apiKeyId}"].get
    )
  end

  defp do_cast_and_validate(conn, operation) do
    case OpenApiSpex.cast_and_validate(@openapi_spec, operation, strip_glob(conn)) do
      {:ok, _} = ok -> ok
      {:error, reasons} -> {:error, {:invalid_request, reasons}}
    end
  end

  defp strip_glob(conn) do
    # Router forwarding introduces a "glob" path parameter
    # TODO: this is probably not a good way to fix this in a generic way
    %{conn | path_params: Map.drop(conn.path_params, ["glob"])}
  end
end
