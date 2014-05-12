class Entity
  def room
    p = parent
    while !p.kind_of?(Room) and !p.nil?
      p = p.parent
    end
    p
  end
end

options(Entity, :portable).default = :not_portable
