import {
  Box,
  Button,
  Dimmer,
  Icon,
  Image,
  Stack,
  Tabs,
  TimeDisplay,
} from 'tgui-core/components';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';

import { Window } from '../layouts';
import {
  type ItemExtraData,
  Uplink,
  type UplinkData,
  type UplinkState,
} from './Uplink';
import { GenericUplink } from './Uplink/GenericUplink';
import {
  ItemExtraData,
  Uplink,
  UplinkData,
  UplinkItem,
  UplinkState,
} from './Uplink';
import '../styles/interfaces/ContractorUplink.scss';

enum EXTRACTION_TYPE {
  Safe = 'safe',
  Unsafe = 'unsafe',
  Dangerous = 'dangerous',
}

type ContractorUplinkData = UplinkData & {
  bounty_targets?: BountyTargets[];
  bomb_list?: BombList[];
  // low of high-to-low range for bounty payouts
  high_bounty?: number;
  low_bounty?: number;
  allCategories?: string[];
  refresh_time?: number;
};

type TabViewProps = ContractorUplinkData & {
  items: ItemExtraData[];
  currentTab: number;
  setTab: (tab: number) => void;
};

type PrimaryObjectiveMenuProps = Partial<ContractorUplinkData> & {};

type BountyTargets = {
  name?: string;
  is_head?: boolean;
  status?: string;
  target_rank?: string;
  location?: string;
  tc_reward?: number;
  credit_reward?: number;
  payout_bonus?: number;
  wanted_message?: string;
  dropoff_location_safe?: string[];
  dropoff_location_unsafe?: string;
  dropoff_location_dangerous?: string;
  mugshot_icon?: string;
  contract_id?: string;
};

type BombList = {
  name?: string;
  active?: boolean;
};

type Tab = {
  title: string;
  content: React.ReactNode;
  // Right-hand hint shown in the shared footer while this tab is open.
  footer: React.ReactNode;
  onSelect?: () => void;
};

export class ContractorUplink extends Uplink {
  // Contractors pay in coins, labelled as such instead of a "TC" suffix.
  costDisplay(item: UplinkItem) {
    return <Box>{item.cost_override_string || `${item.cost} Coins`}</Box>;
  }

  render() {
    const { data } = useBackend<ContractorUplinkData & UplinkData>();
    const { shop_locked } = data;
    const { allCategories, currentTab } = this.state as UplinkState;
    const setTab = (tab: number) => {
      this.setState({ currentTab: tab });
    };
    const items = this.uplinkItems();
    return (
      <Window width={700} height={600} theme="contractor">
        <div>
          <Window.Content>
            <Stack fill vertical>
              <Stack.Item grow>
                <>
                  <TabView
                    {...data}
                    allCategories={allCategories}
                    currentTab={currentTab}
                    setTab={setTab}
                    items={items}
                  />
                  {(shop_locked && !data.debug && (
                    <Dimmer>
                      <Box
                        color="red"
                        fontFamily={'Bahnschrift'}
                        fontSize={3}
                        align={'top'}
                        as="span"
                      >
                        SHOP LOCKED
                      </Box>
                    </Dimmer>
                  )) ||
                    null}
                </>
              </Stack.Item>
            </Stack>
          </Window.Content>
        </div>
      </Window>
    );
  }
}

function TabView(props: TabViewProps) {
  const { act } = useBackend();
  const {
    telecrystals,
    allCategories,
    currentTab,
    setTab,
    items,
    bounty_targets,
    high_bounty,
    low_bounty,
    refresh_time,
  } = props;

  const tabs: Tab[] = [
    {
      title: 'Mission Info',
      content: <MissionInfo />,
      footer: 'Orders are final once accepted',
    },
    {
      title: 'Bounty Targets',
      content: (
        <BountyTargets
          bounty_targets={bounty_targets}
          high_bounty={high_bounty}
          low_bounty={low_bounty}
          refresh_time={refresh_time}
        />
      ),
      footer: 'Complete contracts alive for the full payout bonus',
      onSelect: () => act('show_mugshots'),
    },
    {
      title: 'Marketplace',
      content: (
        <Box className="ContractorMarket" height="100%">
          <GenericUplink
            currency={
              <>
                <Image
                  className="ContractorCoin__icon"
                  src={resolveAsset('coin1.png')}
                />
                {telecrystals} Coins
              </>
            }
            categories={allCategories ?? []}
            items={items}
            handleBuy={(item: ItemExtraData) => {
              if (!item.extraData?.ref) {
                act('buy', { path: item.id });
              } else {
                act('buy', { ref: item.extraData.ref });
              }
            }}
          />
        </Box>
      ),
      footer: 'Coins refund on contract completion',
    },
  ];

  const onTabSelect = (tab: number) => {
    setTab(tab);
    tabs[tab].onSelect?.();
  };

  return (
    <Stack vertical fill id="tabview">
      <Stack.Item>
        <Tabs fluid>
          {tabs.map((tab, index) => (
            <Tabs.Tab
              key={index}
              selected={currentTab === index}
              onClick={() => onTabSelect(index)}
            >
              {tab.title}
            </Tabs.Tab>
          ))}
        </Tabs>
      </Stack.Item>

      <Stack.Item overflowY="auto" grow>
        {tabs[currentTab].content}
      </Stack.Item>

      <Stack.Item>
        <Box className="ContractorFooter">
          <Box as="span">Contractor Support Unit &middot; Secure Channel</Box>
          <Box as="span">{tabs[currentTab].footer}</Box>
        </Box>
      </Stack.Item>
    </Stack>
  );
}

function MissionInfo(props) {
  return <div>Mission Info</div>;
}

function BountyTargets(props: PrimaryObjectiveMenuProps) {
  const {
    bounty_targets,
    low_bounty = 0,
    high_bounty = 30,
    refresh_time = 0,
  } = props;
  const { act } = useBackend();

  const extractionInfo = [
    {
      type: EXTRACTION_TYPE.Safe,
      description:
        "Static location that doesn't provide additional rewards, bring your target to arrivals, departures, solar arrays or lavaland to extract your target.",
    },
    {
      type: EXTRACTION_TYPE.Unsafe,
      description:
        'RNG, any non secure area on the station, grants a small bonus of coins.',
    },
    {
      type: EXTRACTION_TYPE.Dangerous,
      description:
        'Usually a highly restricted area, provides the biggest reward.',
    },
  ];

  const dropoffLocationMessage = (
    target: BountyTargets,
    type: EXTRACTION_TYPE,
  ) => {
    const location = target[`dropoff_location_${type}`];
    if (!location) return 'Location: Unknown';
    const locationString = Array.isArray(location)
      ? location.join(', ')
      : location;
    return `Location: ${locationString}`;
  };

  const targetsElements =
    bounty_targets?.map((target, index) => (
      <Box key={index} className="BountyTarget">
        <Box className="BountyTarget__mug">
          <Image
            width="128px"
            height="128px"
            src={`data:image/jpeg;base64,${target.mugshot_icon}`}
          />
        </Box>
        <Stack vertical>
          <Stack.Item>
            <Box className="BountyTarget__name">
              {target.name}
              {!!target.is_head && (
                <Box as="span" className="BountyTarget__headtag">
                  Head of Staff
                </Box>
              )}
            </Box>
            <Box className="BountyTarget__rank">{target.target_rank}</Box>
            <Box className="BountyTarget__loc">
              <Icon name="location-dot" mr={0.5} />
              {target.location}
            </Box>
          </Stack.Item>

          {!!target.tc_reward && (
            <Stack.Item>
              <Box className="BountyTarget__reward">
                Reward: <b>{target.tc_reward}</b>
                <Image
                  height="32px"
                  src={resolveAsset(
                    `coin${BountyRange(target.tc_reward, low_bounty, high_bounty)}.png`,
                  )}
                />
              </Box>
            </Stack.Item>
          )}

          {!!target.wanted_message && (
            <Stack.Item>
              <Box className="BountyTarget__wanted">
                {target.wanted_message}
              </Box>
            </Stack.Item>
          )}

          <Stack.Item>
            <Box className="BountyTarget__extract-title" mb={0.5}>
              Choose Extraction Type
            </Box>
            <Stack>
              {extractionInfo.map((info) => (
                <Stack.Item grow key={info.type}>
                  <Button
                    fluid
                    textAlign="center"
                    className={`BountyExtract BountyExtract--${info.type}`}
                    onClick={() => {
                      act('call_extraction', {
                        extraction_type: info.type,
                        contract_id: target.contract_id,
                        target: target.name,
                      });
                    }}
                    tooltip={`${info.description}\n\n ${dropoffLocationMessage(target, info.type as EXTRACTION_TYPE)}`}
                  >
                    {info.type.charAt(0).toUpperCase() + info.type.slice(1)}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
        </Stack>
      </Box>
    )) ?? [];

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Box p={2} pb={0}>
          <Box className="ContractorTitle" mb={0.5}>
            Bounty Targets
          </Box>
          <Box className="ContractorSubtle">
            {refresh_time > 0
              ? 'Next refresh in: '
              : 'No active refresh timer. '}
            <Box as="span" className="ContractorSubtle__time">
              <TimeDisplay value={refresh_time} />
            </Box>
          </Box>
        </Box>
      </Stack.Item>

      <Stack.Item grow>
        <Box p={2} pt={1} height="100%" overflowY="auto">
          {targetsElements.length > 0 ? (
            <>{targetsElements}</>
          ) : (
            <ContractorEmpty />
          )}
        </Box>
      </Stack.Item>
    </Stack>
  );
}

function ContractorEmpty() {
  return (
    <Box className="ContractorEmpty">
      <Icon name="crosshairs" size={4} className="ContractorEmpty__icon" />
      <Box className="ContractorEmpty__title">No Active Bounties</Box>
      <Box className="ContractorEmpty__body">
        No bounty targets are currently assigned to your uplink. Fresh dossiers
        are issued automatically each cycle &mdash; check back after the next
        refresh.
      </Box>
      <Box className="ContractorEmpty__hint">
        <Box as="span" className="ContractorEmpty__pulse" />
        Awaiting target dossiers&hellip;
      </Box>
    </Box>
  );
}

/// 1-4 range based on low and range, on whichever is closer to the high end
function BountyRange(value: number, low: number, high: number): number {
  const range = high - low;
  const normalized = (value - low) / range;
  // should never be 0
  const clamped = Math.min(1, Math.max(0, normalized));

  const tier = Math.min(4, Math.floor(clamped * 4));
  return clamp(tier, 1, 4);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
