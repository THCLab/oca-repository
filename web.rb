require 'roda'

class Web < Roda
  route do |r|
    r.root do
      'Hello!'
    end
  end
end
