# The idea of this module is to generate screenshots
# of Urls and save them in Screenshot.
# We use browserstack.com for this and are greatful
# that they give us a free account because we are
# an open-source project.
#
defmodule Vutuv.Browserstack do
  import Ecto.Query
  alias Vutuv.Screenshot
  alias Vutuv.Url
  alias Vutuv.Repo

  def store_screenshot(url) do
    job_id = new_job_id(url)
    :timer.sleep(45000)
    image_url = image_url(job_id)
    image_url
    # TODO: Download the image from image_url and save it as
    # a Screenshot to Url.
  end

  # Ask browserstack.com to generate a screenshot.
  # WARNING: The generation of a screenshot takes time.
  #          You have to wait at least 15 seconds after
  #          new_job_id(url) to run image_url(url).
  #
  def new_job_id(url) do
    hackney = [basic_auth: {Application.fetch_env!(:vutuv, Vutuv.Endpoint)[:browserstack_user], Application.fetch_env!(:vutuv, Vutuv.Endpoint)[:browserstack_password]}]
    headers = ["Content-Type": "application/json", "Accept": "Application/json; Charset=utf-8"]

    case HTTPoison.post "https://www.browserstack.com/screenshots", "{\"browsers\": [{\"os\": \"Windows\", \"os_version\": \"10\", \"browser_version\": \"50.0\", \"browser\": \"chrome\", \"orientation\": \"landscape\"}], \"url\": \"#{url.value}\"}", headers, [ hackney: hackney ] do
      {:ok, %HTTPoison.Response{status_code: 404}} -> nil
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        decoded_body = body |> Poison.decode!
        {:ok, job_id} = Map.fetch(decoded_body, "job_id")
        job_id
      _ -> nil
    end
  end

  # Fetch the image_url of a given job_id
  #
  def image_url(job_id) do
    hackney = [basic_auth: {Application.fetch_env!(:vutuv, Vutuv.Endpoint)[:browserstack_user], Application.fetch_env!(:vutuv, Vutuv.Endpoint)[:browserstack_password]}]

    case HTTPoison.get("https://www.browserstack.com/screenshots/#{job_id}.json", %{},[ hackney: hackney ]) do
      {:ok, %HTTPoison.Response{status_code: 404}} -> nil
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
         decoded_body = body |> Poison.decode!
         {:ok, results} = Map.fetch(decoded_body, "screenshots")
         {:ok, image_url} = Map.fetch(List.first(results), "image_url")
         image_url
      _ -> nil
    end
  end
end