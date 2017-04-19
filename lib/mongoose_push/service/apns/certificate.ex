defmodule MongoosePush.Service.APNS.Certificate do
  @moduledoc false

  require Record
  Record.defrecord :otp_cert,
    Record.extract(:OTPCertificate, from_lib: "public_key/include/public_key.hrl")
  Record.defrecord :tbs_cert,
    Record.extract(:TBSCertificate, from_lib: "public_key/include/public_key.hrl")
  Record.defrecord :cert_ext,
    Record.extract(:Extension,      from_lib: "public_key/include/public_key.hrl")

  # From: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html
  @apns_topic_extn_id {1, 2, 840, 113635, 100, 6, 3, 6}

  def extract_topics(cert_file) do
    {:ok, topics} =
      cert_file
      |> File.read!()
      |> :public_key.pem_decode()
      |> List.keyfind(:Certificate, 0)
      |> get_cert_extension(@apns_topic_extn_id)
      # The module below is compiled with Mix.Task.Compile.Asn1 after Elixir code is compiled,
      # so Elixir compiler may complain about undefined function here. Unfortunately current Mix
      # does not allow for running custom Mix tasks before Elixir's compiler.
      |> :"APNS-Topics".decode(:"APNS-Topics")

    topics
  end

  defp get_cert_extension({:Certificate, cert, _}, ext_id) do
    cert
    |> :public_key.pkix_decode_cert(:otp)
    |> otp_cert(:tbsCertificate)
    |> tbs_cert(:extensions)
    |> List.keyfind(ext_id, cert_ext(:extnID))
    |> cert_ext(:extnValue)
  end
  defp get_cert_extension(unknown, _ext_id), do: IO.puts inspect unknown
end
