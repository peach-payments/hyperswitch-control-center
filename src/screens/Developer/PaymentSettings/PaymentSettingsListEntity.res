open HSwitchSettingTypes
open BusinessMappingUtils

type columns =
  | ProfileName
  | ReturnUrl
  | WebhookUrl

let visibleColumns = [WebhookUrl, ReturnUrl, ProfileName]

let defaultColumns = [ProfileName, ReturnUrl, WebhookUrl]

let allColumns = [ProfileName, ReturnUrl, WebhookUrl]

let getHeading = colType => {
  switch colType {
  | ProfileName => Table.makeHeaderInfo(~key="profile_name", ~title="Profile Name")
  | ReturnUrl => Table.makeHeaderInfo(~key="return_url", ~title="Return URL")
  | WebhookUrl => Table.makeHeaderInfo(~key="webhook_url", ~title="Webhook URL")
  }
}

let getCell = (item: profileEntity, colType): Table.cell => {
  switch colType {
  | ProfileName => Text(item.profile_name)
  | ReturnUrl => Text(item.return_url->Option.getOr(""))
  | WebhookUrl => Text(item.webhook_details.webhook_url->Option.getOr(""))
  }
}

let itemToObjMapper = dict => {
  open LogicUtils
  {
    profile_id: getString(dict, "profile_id", ""),
    profile_name: getString(dict, ProfileName->getStringFromVariant, ""),
    merchant_id: getString(dict, "merchant_id", ""),
    return_url: getOptionString(dict, "return_url"),
    payment_response_hash_key: getOptionString(dict, "payment_response_hash_key"),
    webhook_details: dict
    ->getObj("webhook_details", Dict.make())
    ->BusinessProfileMapper.constructWebhookDetailsObject,
    authentication_connector_details: dict
    ->getObj("webhook_details", Dict.make())
    ->BusinessProfileMapper.constructAuthConnectorObject,
    collect_shipping_details_from_wallet_connector: getOptionBool(
      dict,
      "collect_shipping_details_from_wallet_connector",
    ),
    always_collect_shipping_details_from_wallet_connector: dict->getOptionBool(
      "always_collect_shipping_details_from_wallet_connector",
    ),
    collect_billing_details_from_wallet_connector: dict->getOptionBool(
      "collect_billing_details_from_wallet_connector",
    ),
    always_collect_billing_details_from_wallet_connector: dict->getOptionBool(
      "always_collect_billing_details_from_wallet_connector",
    ),
    outgoing_webhook_custom_http_headers: None,
    metadata: None,
    is_connector_agnostic_mit_enabled: None,
    is_auto_retries_enabled: dict->getOptionBool("is_auto_retries_enabled"),
    max_auto_retries_enabled: dict->getOptionInt("max_auto_retries_enabled"),
    is_click_to_pay_enabled: dict->getOptionBool("is_click_to_pay_enabled"),
    authentication_product_ids: Some(
      dict
      ->getDictfromDict("authentication_product_ids")
      ->JSON.Encode.object,
    ),
    force_3ds_challenge: None,
    is_debit_routing_enabled: None,
    acquirer_configs: dict->getOptionalArrayFromDict("acquirer_configs"),
  }
}

let getItems: JSON.t => array<profileEntity> = json => {
  LogicUtils.getArrayDataFromJson(json, itemToObjMapper)
}

let webhookProfileTableEntity = (~authorization: CommonAuthTypes.authorization) =>
  EntityType.makeEntity(
    ~uri="",
    ~getObjects=getItems,
    ~defaultColumns,
    ~allColumns,
    ~getHeading,
    ~dataKey="",
    ~getCell,
    ~getShowLink={
      profile =>
        GroupAccessUtils.linkForGetShowLinkViaAccess(
          ~url=GlobalVars.appendDashboardPath(~url=`/payment-settings/${profile.profile_id}`),
          ~authorization,
        )
    },
  )
