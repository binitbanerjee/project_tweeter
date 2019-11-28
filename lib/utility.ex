defmodule Utility do
  def get_random(all, self, count, results) do
    if(length(results) < count) do
      random = Enum.random(all)
      results =
        if(random!=self) do
          [random|results]
        else
          results
        end
      get_random(all, self, count, results)
      else
        results
    end
  end

  def get_hashtag do
    hashtags = ["#itIsTrending", "#yayElixir", "#whatsInaHashTag"]
    Enum.random(hashtags)
  end
end
