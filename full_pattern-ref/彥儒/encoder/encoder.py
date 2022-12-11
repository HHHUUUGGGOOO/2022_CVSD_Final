import numpy as np

class Encoder:
    """Polar Codes encoder."""

    def __init__(self,
                 mask: np.array):

        self.n = int(np.log2(mask.shape[0]))
        self.N = mask.shape[0]
        self.mask = mask

    def encode(self, message: np.array) -> np.array:
        """Encode message with a polar code.

        Support both non-systematic and systematic encoding.

        """
        precoded = self._precode(message)
        # print(precoded)
        G = self._generate_G()
        # print(G)
        encoded = np.matmul(precoded, G) % 2
        # print(encoded)

        return encoded

    def _precode(self, message: np.array) -> np.array:
        """Apply polar code mask to information message.

        Replace 1's of polar code mask with bits of information message.

        """
        precoded = np.zeros(self.N, dtype=int)
        precoded[self.mask == 1] = message
        return precoded
    def _generate_G(self):
        G = np.array([[1,0],[1,1]])
        for i in range(self.n - 1):
            # np.array([[G,np.zeros(G.shape)],[G,G]])
            G = np.vstack([np.hstack([G, np.zeros(G.shape)]), np.hstack([G, G])])
        return G

    