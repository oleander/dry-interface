# Dry::Interface [![Main](https://github.com/oleander/dry-interface/actions/workflows/main.yml/badge.svg)](https://github.com/oleander/dry-interface/actions/workflows/main.yml)

``` ruby
require "dry/interface"

class Animal < Dry::Interface
  class Mammal < Concrete
    attribute :id, Value(:mammal)
  end

  class Bird < Value
    attribute :id, Value(:bird)
  end

  class Fish < Abstract
    class Whale < Value
      attribute :id, Value(:whale)
    end

    class Shark < Value
      attribute :id, Value(:shark)
    end
  end
end

Animal.new(id: :mammal) # => Animal::Mammal
Animal.new(id: :shark) # => Animal::Fish::Shark
```
