from typing import Dict, Type, List
from .base import AlgorithmBase
from .dummy import DummyCircleAlgo, DummySquareAlgo # Import dummy algorithms

class AlgorithmRegistry:
    """Manages discovery and access to available algorithms."""

    def __init__(self):
        self._algorithms: Dict[str, Type[AlgorithmBase]] = {}
        self._register_defaults() # Register built-in/dummy algorithms

    def _register_defaults(self):
        """Register the default set of algorithms."""
        # In a real application, this might scan plugins or specific modules
        default_algos = [DummyCircleAlgo, DummySquareAlgo]
        for algo_cls in default_algos:
            self.register_algorithm(algo_cls)

    def register_algorithm(self, algo_cls: Type[AlgorithmBase]):
        """Register a single algorithm class."""
        name = algo_cls.get_name()
        if name in self._algorithms:
            print(f"Warning: Algorithm '{name}' is already registered. Overwriting.")
        self._algorithms[name] = algo_cls
        print(f"Registered algorithm: {name}")

    def list_algorithms(self) -> List[str]:
        """Return a list of names of registered algorithms."""
        return sorted(list(self._algorithms.keys()))

    def get_algorithm_class(self, name: str) -> Type[AlgorithmBase] | None:
        """Get the class for a registered algorithm by name."""
        return self._algorithms.get(name)

    def create_algorithm_instance(self, name: str) -> AlgorithmBase | None:
        """Create an instance of a registered algorithm by name."""
        algo_cls = self.get_algorithm_class(name)
        if algo_cls:
            try:
                return algo_cls() # Instantiate the class
            except Exception as e:
                print(f"Error instantiating algorithm '{name}': {e}")
                return None
        return None

# Optional: Create a global instance for easy access if preferred
# global_algorithm_registry = AlgorithmRegistry() 